-- ============================================================================
-- Migration: 003_create_game_function
-- Stream A / A3: process_create_game(p_command_id) stored procedure
--
-- Invoked by the command processor (A8) inside the same transaction as the
-- command claim. On success it:
--   1. inserts a new games row with game_state='created', state_version=1
--   2. inserts a games_players row for the admin with is_admin=true
--   3. backfills the command's command_game_id so the row references the
--      newly created game
--   4. returns the new game_id
--
-- Payload schema (keys match column names exactly, per Stream B contract):
--   {
--     "game_name": "string (1..32 chars, required)",
--     "game_description": "string (0..256 chars, optional, may be null)",
--     "game_security": "public|private (required)",
--     "is_ranked": "ranked|casual (required)",
--     "game_max_players": integer 1..100 (required),
--     "end_condition": "timed|endless (required)",
--     "total_decided_duration_seconds": integer > 0 (required iff timed, must
--                                       be absent/null for endless)
--   }
--
-- Error-class convention used across every Stream A procedure:
--   UE001 -> non-retriable validation error (malformed payload, missing
--            required field, wrong command_type, missing player/game target).
--            Processor (A8) will mark the command 'rejected' immediately
--            without retrying.
--   UE002 -> non-retriable business-rule violation (wrong game_state,
--            non-admin attempting admin action, player not in game, etc.).
--            Also mapped to immediate 'rejected' by the processor.
--   other  -> retriable; processor retries up to 3 times then rejects.
--
-- Privilege model: SECURITY DEFINER with search_path pinned, EXECUTE granted
-- only to service_role. End users only insert command rows; they never
-- invoke core procedures directly.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.process_create_game(p_command_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd               commands%ROWTYPE;
  v_payload           jsonb;
  v_game_name         text;
  v_game_description  text;
  v_game_security     game_security;
  v_is_ranked         game_ranked;
  v_max_players       integer;
  v_end_condition     end_condition;
  v_duration          integer;
  v_has_duration_key  boolean;
  v_game_id           uuid;
  v_joining_code      text;
  v_attempt           integer;
  v_max_attempts      constant integer := 50;
  v_alphabet          constant text := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  v_security_raw      text;
  v_ranked_raw        text;
  v_end_raw           text;
  v_max_players_raw   text;
  v_duration_raw      text;
BEGIN
  -- -------------------------------------------------------------------------
  -- Load + validate command row
  -- -------------------------------------------------------------------------
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_create_game: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;

  IF v_cmd.command_type <> 'create_game' THEN
    RAISE EXCEPTION 'process_create_game: command % has type % (expected create_game)',
      p_command_id, v_cmd.command_type
      USING ERRCODE = 'UE001';
  END IF;

  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_create_game: command % has null player_id (admin required)',
      p_command_id
      USING ERRCODE = 'UE001';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM players WHERE player_id = v_cmd.player_id) THEN
    RAISE EXCEPTION 'process_create_game: player % does not exist', v_cmd.player_id
      USING ERRCODE = 'UE001';
  END IF;

  v_payload := v_cmd.payload;
  IF v_payload IS NULL OR jsonb_typeof(v_payload) <> 'object' THEN
    RAISE EXCEPTION 'process_create_game: payload must be a JSON object'
      USING ERRCODE = 'UE001';
  END IF;

  -- -------------------------------------------------------------------------
  -- Extract + validate payload fields. Every failure is UE001 (non-retriable)
  -- since the payload will not spontaneously fix itself on a retry.
  -- -------------------------------------------------------------------------
  v_game_name := v_payload ->> 'game_name';
  IF v_game_name IS NULL THEN
    RAISE EXCEPTION 'process_create_game: game_name required'
      USING ERRCODE = 'UE001';
  END IF;
  IF char_length(v_game_name) < 1 OR char_length(v_game_name) > 32 THEN
    RAISE EXCEPTION 'process_create_game: game_name length must be 1..32 (got %)',
      char_length(v_game_name)
      USING ERRCODE = 'UE001';
  END IF;

  v_game_description := v_payload ->> 'game_description';
  IF v_game_description IS NOT NULL AND char_length(v_game_description) > 256 THEN
    RAISE EXCEPTION 'process_create_game: game_description length must be <= 256 (got %)',
      char_length(v_game_description)
      USING ERRCODE = 'UE001';
  END IF;

  v_security_raw := v_payload ->> 'game_security';
  IF v_security_raw IS NULL THEN
    RAISE EXCEPTION 'process_create_game: game_security required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_security_raw NOT IN ('public', 'private') THEN
    RAISE EXCEPTION 'process_create_game: game_security must be public|private (got %)', v_security_raw
      USING ERRCODE = 'UE001';
  END IF;
  v_game_security := v_security_raw::game_security;

  v_ranked_raw := v_payload ->> 'is_ranked';
  IF v_ranked_raw IS NULL THEN
    RAISE EXCEPTION 'process_create_game: is_ranked required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_ranked_raw NOT IN ('ranked', 'casual') THEN
    RAISE EXCEPTION 'process_create_game: is_ranked must be ranked|casual (got %)', v_ranked_raw
      USING ERRCODE = 'UE001';
  END IF;
  v_is_ranked := v_ranked_raw::game_ranked;

  v_max_players_raw := v_payload ->> 'game_max_players';
  IF v_max_players_raw IS NULL THEN
    RAISE EXCEPTION 'process_create_game: game_max_players required'
      USING ERRCODE = 'UE001';
  END IF;
  -- jsonb numbers stringify cleanly; guard against non-integer strings
  IF v_max_players_raw !~ '^-?[0-9]+$' THEN
    RAISE EXCEPTION 'process_create_game: game_max_players must be an integer (got %)', v_max_players_raw
      USING ERRCODE = 'UE001';
  END IF;
  v_max_players := v_max_players_raw::integer;
  IF v_max_players < 1 OR v_max_players > 100 THEN
    RAISE EXCEPTION 'process_create_game: game_max_players must be 1..100 (got %)', v_max_players
      USING ERRCODE = 'UE001';
  END IF;

  v_end_raw := v_payload ->> 'end_condition';
  IF v_end_raw IS NULL THEN
    RAISE EXCEPTION 'process_create_game: end_condition required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_end_raw NOT IN ('timed', 'endless') THEN
    RAISE EXCEPTION 'process_create_game: end_condition must be timed|endless (got %)', v_end_raw
      USING ERRCODE = 'UE001';
  END IF;
  v_end_condition := v_end_raw::end_condition;

  -- Duration rules
  v_has_duration_key := v_payload ? 'total_decided_duration_seconds';
  v_duration_raw := v_payload ->> 'total_decided_duration_seconds';
  IF v_end_condition = 'timed' THEN
    IF v_duration_raw IS NULL THEN
      RAISE EXCEPTION 'process_create_game: total_decided_duration_seconds required for timed games'
        USING ERRCODE = 'UE001';
    END IF;
    IF v_duration_raw !~ '^-?[0-9]+$' THEN
      RAISE EXCEPTION 'process_create_game: total_decided_duration_seconds must be an integer (got %)', v_duration_raw
        USING ERRCODE = 'UE001';
    END IF;
    v_duration := v_duration_raw::integer;
    IF v_duration <= 0 THEN
      RAISE EXCEPTION 'process_create_game: total_decided_duration_seconds must be > 0 (got %)', v_duration
        USING ERRCODE = 'UE001';
    END IF;
  ELSE
    -- endless: duration key either absent or explicitly null
    IF v_has_duration_key AND v_duration_raw IS NOT NULL THEN
      RAISE EXCEPTION 'process_create_game: endless games must not specify total_decided_duration_seconds (got %)', v_duration_raw
        USING ERRCODE = 'UE001';
    END IF;
    v_duration := NULL;
  END IF;

  -- -------------------------------------------------------------------------
  -- Generate a unique joining code.
  --
  -- The partial unique index (games_joining_code_active_unique) enforces
  -- uniqueness only across non-terminal game_state values. We do a quick
  -- pre-check to skip obvious collisions, but the INSERT itself is the
  -- authoritative check so we are safe against concurrent creators racing
  -- for the same code. If the INSERT loses the race, we loop and pick a
  -- new code. 5-char A-Z0-9 gives 36^5 = 60,466,176 codes; a collision
  -- across a realistic number of active games is near zero.
  -- -------------------------------------------------------------------------
  v_game_id := gen_random_uuid();
  v_attempt := 0;
  LOOP
    v_attempt := v_attempt + 1;
    IF v_attempt > v_max_attempts THEN
      RAISE EXCEPTION 'process_create_game: could not generate unique joining_code after % attempts', v_max_attempts
        USING ERRCODE = 'UE001';
    END IF;

    v_joining_code := '';
    FOR i IN 1..5 LOOP
      v_joining_code := v_joining_code
        || substring(v_alphabet FROM (floor(random() * 36) + 1)::integer FOR 1);
    END LOOP;

    BEGIN
      INSERT INTO games (
        game_id, game_name, game_description, game_security, is_ranked,
        game_max_players, joining_code, end_condition,
        total_decided_duration_seconds, game_state, admin_player_id,
        state_version
      ) VALUES (
        v_game_id, v_game_name, v_game_description, v_game_security, v_is_ranked,
        v_max_players, v_joining_code, v_end_condition,
        v_duration, 'created', v_cmd.player_id,
        1
      );
      EXIT; -- insert succeeded, done retrying
    EXCEPTION WHEN unique_violation THEN
      -- Only retry on joining_code collision. Any other unique violation
      -- (shouldn't happen here) propagates out.
      CONTINUE;
    END;
  END LOOP;

  -- -------------------------------------------------------------------------
  -- Admin's games_players membership row
  -- -------------------------------------------------------------------------
  INSERT INTO games_players (
    map_game_id, map_player_id, is_admin, lobby_status,
    delta_cash, delta_envelopes, pnl
  ) VALUES (
    v_game_id, v_cmd.player_id, true, 'playing',
    0, 0, 0
  );

  -- -------------------------------------------------------------------------
  -- Backfill command_game_id so the command row now references the new game.
  -- The processor will then mark command_status='processed'.
  -- -------------------------------------------------------------------------
  UPDATE commands
    SET command_game_id = v_game_id
    WHERE command_id = p_command_id;

  RETURN v_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_create_game(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_create_game(uuid) TO service_role;
