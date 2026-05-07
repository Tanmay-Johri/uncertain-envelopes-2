-- ============================================================================
-- Migration: 004_create_lobby_functions
-- Stream A / A4: lobby stored procedures
--
--   process_join_game(p_command_id)   — player joins a game (by code or
--                                       directly). Allowed in game_state IN
--                                       ('created','trading_started') per
--                                       PRD ("They can join the game (if the
--                                       game hasn't hit maximum number of
--                                       players yet)"). Enforces max_players,
--                                       not-already-joined, and bumps
--                                       state_version.
--
--   process_leave_game(p_command_id)  — player leaves their own lobby. Only
--                                       allowed in game_state='created' per
--                                       PRD ("Players cannot exit a game once
--                                       it enters the 'trading_started'
--                                       stage"). Admin cannot leave (admin
--                                       must discard instead). Deletes the
--                                       games_players row and bumps
--                                       state_version.
--
--   process_kick_player(p_command_id) — admin kicks a member. Payload:
--                                       { "target_player_id": "<uuid>" }.
--                                       Only in game_state='created'. Caller
--                                       must be admin, target must be in game
--                                       and must not be the admin themselves.
--                                       Deletes the target row and bumps
--                                       state_version.
--
-- Error classes (see 003_create_game_function.sql header):
--   UE001 — non-retriable validation: command not found, wrong command_type,
--           null player_id / command_game_id, missing/malformed payload.
--   UE002 — non-retriable business-rule violation: wrong game_state, game
--           full, already joined, admin-leaving, non-admin-kicking,
--           target-not-in-game, self-kick.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- process_join_game
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_join_game(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd              commands%ROWTYPE;
  v_game             games%ROWTYPE;
  v_current_players  integer;
BEGIN
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_join_game: command % not found', p_command_id USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'join_game' THEN
    RAISE EXCEPTION 'process_join_game: command % has type % (expected join_game)', p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_join_game: command_game_id required' USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_join_game: player_id required' USING ERRCODE = 'UE001';
  END IF;

  -- Lock game row for the duration of the join to serialise concurrent
  -- joiners against the max_players check (two players both grabbing the
  -- last slot).
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_join_game: game % not found', v_cmd.command_game_id USING ERRCODE = 'UE001';
  END IF;

  IF v_game.game_state NOT IN ('created', 'trading_started') THEN
    RAISE EXCEPTION 'process_join_game: game_state % does not allow joining', v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  IF EXISTS (
    SELECT 1 FROM games_players
    WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id
  ) THEN
    RAISE EXCEPTION 'process_join_game: player % already in game %', v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  SELECT count(*) INTO v_current_players
  FROM games_players WHERE map_game_id = v_cmd.command_game_id;

  IF v_current_players >= v_game.game_max_players THEN
    RAISE EXCEPTION 'process_join_game: game is at max_players (%)', v_game.game_max_players USING ERRCODE = 'UE002';
  END IF;

  INSERT INTO games_players (
    map_game_id, map_player_id, is_admin, lobby_status,
    delta_cash, delta_envelopes, pnl
  ) VALUES (
    v_cmd.command_game_id, v_cmd.player_id, false, 'playing',
    0, 0, 0
  );

  UPDATE games
    SET state_version = state_version + 1
    WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_join_game(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_join_game(uuid) TO service_role;

-- ---------------------------------------------------------------------------
-- process_leave_game
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_leave_game(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd     commands%ROWTYPE;
  v_game    games%ROWTYPE;
  v_member  games_players%ROWTYPE;
BEGIN
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_leave_game: command % not found', p_command_id USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'leave_game' THEN
    RAISE EXCEPTION 'process_leave_game: command % has type % (expected leave_game)', p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_leave_game: command_game_id required' USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_leave_game: player_id required' USING ERRCODE = 'UE001';
  END IF;

  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_leave_game: game % not found', v_cmd.command_game_id USING ERRCODE = 'UE001';
  END IF;

  -- PRD: "Players cannot exit a game once it enters the 'trading_started' stage."
  IF v_game.game_state <> 'created' THEN
    RAISE EXCEPTION 'process_leave_game: game_state % does not allow leaving', v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  SELECT * INTO v_member
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_leave_game: player % not in game %', v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- Admin cannot leave: they must discard the game (process_discard_game) instead.
  IF v_member.is_admin THEN
    RAISE EXCEPTION 'process_leave_game: admin cannot leave; use discard_game instead' USING ERRCODE = 'UE002';
  END IF;

  DELETE FROM games_players
  WHERE games_players_row_id = v_member.games_players_row_id;

  UPDATE games
    SET state_version = state_version + 1
    WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_leave_game(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_leave_game(uuid) TO service_role;

-- ---------------------------------------------------------------------------
-- process_kick_player
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_kick_player(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd            commands%ROWTYPE;
  v_game           games%ROWTYPE;
  v_caller_row     games_players%ROWTYPE;
  v_target_row     games_players%ROWTYPE;
  v_target_raw     text;
  v_target_id      uuid;
BEGIN
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_kick_player: command % not found', p_command_id USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'kick_player' THEN
    RAISE EXCEPTION 'process_kick_player: command % has type % (expected kick_player)', p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_kick_player: command_game_id required' USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_kick_player: player_id (admin caller) required' USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.payload IS NULL OR jsonb_typeof(v_cmd.payload) <> 'object' THEN
    RAISE EXCEPTION 'process_kick_player: payload must be a JSON object' USING ERRCODE = 'UE001';
  END IF;

  v_target_raw := v_cmd.payload ->> 'target_player_id';
  IF v_target_raw IS NULL THEN
    RAISE EXCEPTION 'process_kick_player: payload.target_player_id required' USING ERRCODE = 'UE001';
  END IF;
  BEGIN
    v_target_id := v_target_raw::uuid;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_kick_player: payload.target_player_id is not a valid uuid (got %)', v_target_raw USING ERRCODE = 'UE001';
  END;

  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_kick_player: game % not found', v_cmd.command_game_id USING ERRCODE = 'UE001';
  END IF;

  IF v_game.game_state <> 'created' THEN
    RAISE EXCEPTION 'process_kick_player: game_state % does not allow kicking', v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- Caller must be a member of the game AND be its admin.
  SELECT * INTO v_caller_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_kick_player: caller % not in game %', v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;
  IF NOT v_caller_row.is_admin THEN
    RAISE EXCEPTION 'process_kick_player: caller % is not admin of game %', v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- Admin cannot kick themselves (would leave the game without an admin).
  IF v_target_id = v_cmd.player_id THEN
    RAISE EXCEPTION 'process_kick_player: admin cannot kick themselves' USING ERRCODE = 'UE002';
  END IF;

  SELECT * INTO v_target_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_target_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_kick_player: target % not in game %', v_target_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  DELETE FROM games_players
  WHERE games_players_row_id = v_target_row.games_players_row_id;

  UPDATE games
    SET state_version = state_version + 1
    WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_kick_player(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_kick_player(uuid) TO service_role;
