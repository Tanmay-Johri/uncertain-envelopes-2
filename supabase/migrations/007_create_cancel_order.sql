-- ============================================================================
-- Migration: 007_create_cancel_order
-- Stream A / A7: cancel resting order
--
--   process_cancel_order(p_command_id uuid)
--       Command wrapper. Validates command row, payload { "order_id": "<uuid>" },
--       game state (must be trading_started), order exists in that game, order
--       status is order_resting, order owner is the command's player_id.
--       Sets orders.status = 'cancelled'. Bumps games.state_version by 1.
--       Does not modify quantity_current, games_players deltas, or executions.
--
-- Error classes (match prior procs):
--   UE001 — non-retriable validation: command not found, wrong command_type,
--           null required field, missing/malformed payload, invalid order_id
--           string, order not found, order's game_id ≠ command_game_id
--   UE002 — non-retriable business rule: game_state ≠ trading_started,
--           order status ≠ order_resting, order owned by another player
-- ============================================================================

CREATE OR REPLACE FUNCTION public.process_cancel_order(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd        commands%ROWTYPE;
  v_game       games%ROWTYPE;
  v_ord        orders%ROWTYPE;
  v_oid_raw    text;
  v_order_id   uuid;
BEGIN
  -- ---- Prologue: validate command row ------------------------------------ --
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_cancel_order: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'cancel_order' THEN
    RAISE EXCEPTION 'process_cancel_order: command % has type % (expected cancel_order)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_cancel_order: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_cancel_order: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Payload: order_id ------------------------------------------------- --
  IF v_cmd.payload IS NULL OR jsonb_typeof(v_cmd.payload) <> 'object' THEN
    RAISE EXCEPTION 'process_cancel_order: payload must be a JSON object'
      USING ERRCODE = 'UE001';
  END IF;

  v_oid_raw := v_cmd.payload ->> 'order_id';
  IF v_oid_raw IS NULL OR btrim(v_oid_raw) = '' THEN
    RAISE EXCEPTION 'process_cancel_order: payload.order_id required'
      USING ERRCODE = 'UE001';
  END IF;
  BEGIN
    v_order_id := v_oid_raw::uuid;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_cancel_order: payload.order_id is not a valid uuid (got %)',
      v_oid_raw USING ERRCODE = 'UE001';
  END;

  -- ---- Lock game + state gate -------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_cancel_order: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  IF v_game.game_state <> 'trading_started' THEN
    RAISE EXCEPTION 'process_cancel_order: game_state % does not allow cancel_order (expected trading_started)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- ---- Lock order + ownership / status ------------------------------------ --
  SELECT * INTO v_ord FROM orders WHERE order_id = v_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_cancel_order: order % not found', v_order_id
      USING ERRCODE = 'UE001';
  END IF;

  IF v_ord.game_id <> v_cmd.command_game_id THEN
    RAISE EXCEPTION 'process_cancel_order: order % belongs to game % (command references game %)',
      v_order_id, v_ord.game_id, v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  IF v_ord.created_by_player_id <> v_cmd.player_id THEN
    RAISE EXCEPTION 'process_cancel_order: order % not owned by player %',
      v_order_id, v_cmd.player_id
      USING ERRCODE = 'UE002';
  END IF;

  IF v_ord.status <> 'order_resting' THEN
    RAISE EXCEPTION 'process_cancel_order: order % has status % (expected order_resting)',
      v_order_id, v_ord.status
      USING ERRCODE = 'UE002';
  END IF;

  UPDATE orders
  SET    status = 'cancelled'::order_status
  WHERE  order_id = v_order_id;

  UPDATE games
  SET    state_version = state_version + 1
  WHERE  game_id = v_game.game_id;
END;
$$;

REVOKE ALL   ON FUNCTION public.process_cancel_order(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_cancel_order(uuid) TO service_role;
