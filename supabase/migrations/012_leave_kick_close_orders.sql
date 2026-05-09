-- A-GAP-5: when a player is removed from the lobby (leave or kick), any of
-- their non-terminal orders in that game must be marked `game_ended` so
-- they cannot resurrect after re-joining a later session.

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

  IF v_game.game_state <> 'created' THEN
    RAISE EXCEPTION 'process_leave_game: game_state % does not allow leaving', v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  SELECT * INTO v_member
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_leave_game: player % not in game %', v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  IF v_member.is_admin THEN
    RAISE EXCEPTION 'process_leave_game: admin cannot leave; use discard_game instead' USING ERRCODE = 'UE002';
  END IF;

  DELETE FROM games_players
  WHERE games_players_row_id = v_member.games_players_row_id;

  UPDATE orders SET status = 'game_ended'
  WHERE game_id = v_cmd.command_game_id
    AND created_by_player_id = v_cmd.player_id
    AND status IN ('in_queue','being_processed','order_resting');

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

  SELECT * INTO v_caller_row
  FROM games_players
  WHERE map_game_id = v_cmd.command_game_id AND map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_kick_player: caller % not in game %', v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;
  IF NOT v_caller_row.is_admin THEN
    RAISE EXCEPTION 'process_kick_player: caller % is not admin of game %', v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

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

  UPDATE orders SET status = 'game_ended'
  WHERE game_id = v_cmd.command_game_id
    AND created_by_player_id = v_target_id
    AND status IN ('in_queue','being_processed','order_resting');

  UPDATE games
    SET state_version = state_version + 1
    WHERE game_id = v_cmd.command_game_id;
END;
$$;

REVOKE ALL ON FUNCTION public.process_kick_player(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_kick_player(uuid) TO service_role;
