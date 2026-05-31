-- ============================================================================
-- Migration: 020_games_game_name_active_unique
-- Enforce unique game_name among non-terminal games (same active states as
-- games_joining_code_active_unique). Terminal games (game_finalised,
-- discarded) may reuse names.
-- ============================================================================

CREATE UNIQUE INDEX games_game_name_active_unique
  ON public.games (game_name)
  WHERE game_state IN ('created', 'trading_started', 'trading_ended');

-- Patch process_create_game: pre-check + joining_code-only retry on conflict.
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
    IF v_has_duration_key AND v_duration_raw IS NOT NULL THEN
      RAISE EXCEPTION 'process_create_game: endless games must not specify total_decided_duration_seconds (got %)', v_duration_raw
        USING ERRCODE = 'UE001';
    END IF;
    v_duration := NULL;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM games g
    WHERE g.game_name = v_game_name
      AND g.game_state IN ('created', 'trading_started', 'trading_ended')
  ) THEN
    RAISE EXCEPTION 'process_create_game: a game with this name is already active'
      USING ERRCODE = 'UE001';
  END IF;

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
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      IF EXISTS (
        SELECT 1
        FROM games g
        WHERE g.joining_code = v_joining_code
          AND g.game_state IN ('created', 'trading_started', 'trading_ended')
      ) THEN
        CONTINUE;
      END IF;
      IF EXISTS (
        SELECT 1
        FROM games g
        WHERE g.game_name = v_game_name
          AND g.game_state IN ('created', 'trading_started', 'trading_ended')
      ) THEN
        RAISE EXCEPTION 'process_create_game: a game with this name is already active'
          USING ERRCODE = 'UE001';
      END IF;
      RAISE;
    END;
  END LOOP;

  INSERT INTO games_players (
    map_game_id, map_player_id, is_admin, lobby_status,
    delta_cash, delta_envelopes, pnl
  ) VALUES (
    v_game_id, v_cmd.player_id, true, 'playing',
    0, 0, 0
  );

  UPDATE commands
    SET command_game_id = v_game_id
    WHERE command_id = p_command_id;

  RETURN v_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_create_game(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_create_game(uuid) TO service_role;
