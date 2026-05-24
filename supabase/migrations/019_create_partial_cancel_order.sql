-- ============================================================================
-- Migration: 019_create_partial_cancel_order
--
--   process_partial_cancel_order(p_command_id uuid)
--       Validates command row, payload { "order_id": "<uuid>",
--       "quantity_to_cancel": <positive int> }, game trading_started,
--       order resting, same ownership checks as process_cancel_order.
--
--       If quantity_to_cancel >= quantity_current: full cancel — set
--       status = cancelled (quantity_current unchanged, same as cancel_order).
--       Else: decrement quantity_current only; order_created_at unchanged;
--       status stays order_resting.
--
--       Bumps games.state_version by 1.
--
-- Error classes (match prior procs):
--   UE001 — validation: command not found, wrong type, bad payload,
--           missing/malformed order_id or quantity_to_cancel, order not found,
--           cross-game mismatch, quantity_to_cancel < 1 or not a valid int
--   UE002 — business: game_state ≠ trading_started, order not resting,
--           order owned by another player
-- ============================================================================

CREATE OR REPLACE FUNCTION public.process_partial_cancel_order(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd             commands%ROWTYPE;
  v_game            games%ROWTYPE;
  v_ord             orders%ROWTYPE;
  v_oid_raw         text;
  v_order_id        uuid;
  v_qty_raw         text;
  v_qty_to_cancel   integer;
BEGIN
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_partial_cancel_order: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'partial_cancel_order' THEN
    RAISE EXCEPTION 'process_partial_cancel_order: command % has type % (expected partial_cancel_order)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_partial_cancel_order: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_partial_cancel_order: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  IF v_cmd.payload IS NULL OR jsonb_typeof(v_cmd.payload) <> 'object' THEN
    RAISE EXCEPTION 'process_partial_cancel_order: payload must be a JSON object'
      USING ERRCODE = 'UE001';
  END IF;

  v_oid_raw := v_cmd.payload ->> 'order_id';
  IF v_oid_raw IS NULL OR btrim(v_oid_raw) = '' THEN
    RAISE EXCEPTION 'process_partial_cancel_order: payload.order_id required'
      USING ERRCODE = 'UE001';
  END IF;
  BEGIN
    v_order_id := v_oid_raw::uuid;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_partial_cancel_order: payload.order_id is not a valid uuid (got %)',
      v_oid_raw USING ERRCODE = 'UE001';
  END;

  v_qty_raw := v_cmd.payload ->> 'quantity_to_cancel';
  IF v_qty_raw IS NULL OR btrim(v_qty_raw) = '' THEN
    RAISE EXCEPTION 'process_partial_cancel_order: payload.quantity_to_cancel required'
      USING ERRCODE = 'UE001';
  END IF;
  BEGIN
    v_qty_to_cancel := v_qty_raw::integer;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_partial_cancel_order: payload.quantity_to_cancel must be a valid integer (got %)',
      v_qty_raw USING ERRCODE = 'UE001';
  END;
  IF v_qty_to_cancel < 1 THEN
    RAISE EXCEPTION 'process_partial_cancel_order: quantity_to_cancel must be >= 1 (got %)',
      v_qty_to_cancel USING ERRCODE = 'UE001';
  END IF;

  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_partial_cancel_order: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  IF v_game.game_state <> 'trading_started' THEN
    RAISE EXCEPTION 'process_partial_cancel_order: game_state % does not allow partial_cancel_order (expected trading_started)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  SELECT * INTO v_ord FROM orders WHERE order_id = v_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_partial_cancel_order: order % not found', v_order_id
      USING ERRCODE = 'UE001';
  END IF;

  IF v_ord.game_id <> v_cmd.command_game_id THEN
    RAISE EXCEPTION 'process_partial_cancel_order: order % belongs to game % (command references game %)',
      v_order_id, v_ord.game_id, v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  IF v_ord.created_by_player_id <> v_cmd.player_id THEN
    RAISE EXCEPTION 'process_partial_cancel_order: order % not owned by player %',
      v_order_id, v_cmd.player_id
      USING ERRCODE = 'UE002';
  END IF;

  IF v_ord.status <> 'order_resting' THEN
    RAISE EXCEPTION 'process_partial_cancel_order: order % has status % (expected order_resting)',
      v_order_id, v_ord.status
      USING ERRCODE = 'UE002';
  END IF;

  IF v_qty_to_cancel >= v_ord.quantity_current THEN
    UPDATE orders
    SET    status = 'cancelled'::order_status
    WHERE  order_id = v_order_id;
  ELSE
    UPDATE orders
    SET    quantity_current = quantity_current - v_qty_to_cancel
    WHERE  order_id = v_order_id;
  END IF;

  UPDATE games
  SET    state_version = state_version + 1
  WHERE  game_id = v_game.game_id;
END;
$$;

REVOKE ALL   ON FUNCTION public.process_partial_cancel_order(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_partial_cancel_order(uuid) TO service_role;
