-- ============================================================================
-- Migration: 006_create_order_matching
-- Stream A / A6: order matching engine
--
-- Functions (all SECURITY DEFINER, callable only by service_role):
--
--   match_order(p_order_id uuid)
--       Internal engine. Receives a single 'being_processed' order, scans
--       the resting book for crossable counterparts, creates executions,
--       updates both players' delta_cash / delta_envelopes in games_players,
--       updates games.last_traded_price, finalises the incoming order's
--       status, and bumps games.state_version exactly once.
--       Called exclusively by process_create_order; not called directly by
--       the command processor.
--
--   process_create_order(p_command_id uuid)
--       Command wrapper. Validates the command, game state, player
--       membership, and payload; inserts the orders row; calls match_order.
--       Does NOT bump state_version directly — delegates entirely to
--       match_order.
--
-- Matching rules (per PRD):
--   Buy incoming:
--     - Counterparts: resting 'limit_sell' orders only (market orders never
--       reach order_resting, so only limit sells appear in the book).
--     - Price condition: limit_buy → resting.price_per_stock <=
--       incoming.price_per_stock; market_buy → no price filter.
--     - Sort: price ASC, then order_created_at ASC (cheapest first, FIFO).
--   Sell incoming: symmetric (limit_buy counterparts, price condition
--     inverted, sort: price DESC then order_created_at ASC).
--   Execution price: always the resting order's price_per_stock.
--   Incoming order final status:
--     - Fully filled (quantity_current = 0) → order_closed
--     - Limit with remainder → order_resting
--     - Market with remainder → order_closed
--
-- Locked design decisions (planning session):
--   Self-match: allowed — no filter on created_by_player_id.
--   Payload field names: 'type', 'quantity_initial', 'price_per_stock'
--     (aligned with stream-b command_repository.dart).
--   Delta precision: no rounding during execution; arbitrary-precision
--     NUMERIC; rounding only at finalise time (A5 decision).
--   state_version: bumped exactly once inside match_order regardless of
--     how many execution legs are created.
--
-- Error classes (inherited):
--   UE001 — non-retriable validation: command not found, wrong type,
--           null required field, missing/malformed payload, invalid order
--           type string, quantity ≤ 0, price missing/invalid for limit,
--           price present for market.
--   UE002 — non-retriable business-rule: wrong game_state, player not in
--           game.
-- ============================================================================


-- ============================================================================
-- match_order
-- ============================================================================
CREATE OR REPLACE FUNCTION public.match_order(p_order_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_order           orders%ROWTYPE;
  v_resting         orders%ROWTYPE;
  v_exec_qty        integer;
  v_exec_price      numeric;
  v_last_exec_price numeric;
  v_exec_count      integer := 0;
  v_is_buy          boolean;
  v_cursor          REFCURSOR;
BEGIN
  -- ---- Lock and validate incoming order ------------------------------------ --
  SELECT * INTO v_order FROM orders WHERE order_id = p_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_order: order % not found', p_order_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_order.status <> 'being_processed' THEN
    RAISE EXCEPTION 'match_order: order % has status % (expected being_processed)',
      p_order_id, v_order.status USING ERRCODE = 'UE001';
  END IF;

  v_is_buy := v_order.type IN ('limit_buy', 'market_buy');

  -- ---- Open counterpart cursor --------------------------------------------- --
  -- Only limit orders ever reach order_resting (market orders are immediately
  -- closed if unfilled), so the counterpart book contains only limit_sell
  -- (for buys) or limit_buy (for sells).
  IF v_is_buy THEN
    OPEN v_cursor FOR
      SELECT * FROM orders
      WHERE  game_id = v_order.game_id
        AND  status  = 'order_resting'
        AND  type    = 'limit_sell'
        -- Price crossover: market_buy matches any resting sell price;
        -- limit_buy only crosses where resting price <= incoming price.
        AND  (v_order.type = 'market_buy'
              OR price_per_stock <= v_order.price_per_stock)
      ORDER BY price_per_stock ASC, order_created_at ASC   -- cheapest first, FIFO
      FOR UPDATE;
  ELSE
    OPEN v_cursor FOR
      SELECT * FROM orders
      WHERE  game_id = v_order.game_id
        AND  status  = 'order_resting'
        AND  type    = 'limit_buy'
        -- Price crossover: market_sell matches any resting buy price;
        -- limit_sell only crosses where resting price >= incoming price.
        AND  (v_order.type = 'market_sell'
              OR price_per_stock >= v_order.price_per_stock)
      ORDER BY price_per_stock DESC, order_created_at ASC  -- highest first, FIFO
      FOR UPDATE;
  END IF;

  -- ---- Matching loop ------------------------------------------------------- --
  LOOP
    -- Check at top: stop if incoming order is already fully filled.
    EXIT WHEN v_order.quantity_current = 0;

    FETCH v_cursor INTO v_resting;
    EXIT WHEN NOT FOUND;

    -- Execution quantity = min of both remaining quantities.
    v_exec_qty   := LEAST(v_order.quantity_current, v_resting.quantity_current);
    -- Execution price is always the resting order's price (PRD rule).
    v_exec_price := v_resting.price_per_stock;

    -- ---- Record execution ------------------------------------------------- --
    INSERT INTO executions (
      executions_game_id,
      buy_order_id,
      sell_order_id,
      quantity,
      execution_price
    ) VALUES (
      v_order.game_id,
      CASE WHEN v_is_buy THEN p_order_id        ELSE v_resting.order_id END,
      CASE WHEN v_is_buy THEN v_resting.order_id ELSE p_order_id        END,
      v_exec_qty,
      v_exec_price
    );

    -- ---- Update incoming order quantity ----------------------------------- --
    -- CRITICAL: decrement the local variable too, so the LEAST() call in the
    -- next iteration sees the updated remaining quantity.
    v_order.quantity_current := v_order.quantity_current - v_exec_qty;
    UPDATE orders
    SET    quantity_current = v_order.quantity_current
    WHERE  order_id = p_order_id;

    -- ---- Update resting order quantity ------------------------------------ --
    IF v_resting.quantity_current = v_exec_qty THEN
      -- Fully filled resting order: close it.
      UPDATE orders
      SET    quantity_current = 0,
             status           = 'order_closed'
      WHERE  order_id = v_resting.order_id;
    ELSE
      -- Partially filled: decrement quantity; status remains order_resting.
      UPDATE orders
      SET    quantity_current = quantity_current - v_exec_qty
      WHERE  order_id = v_resting.order_id;
    END IF;

    -- ---- Update games_players deltas -------------------------------------- --
    -- Buyer: pays cash (delta_cash decreases), receives envelopes (increases).
    -- Seller: receives cash (increases), gives envelopes (decreases).
    IF v_is_buy THEN
      -- Incoming order is the buyer.
      UPDATE games_players
      SET    delta_cash      = delta_cash      - (v_exec_price * v_exec_qty),
             delta_envelopes = delta_envelopes + v_exec_qty
      WHERE  map_game_id  = v_order.game_id
        AND  map_player_id = v_order.created_by_player_id;

      -- Resting order is the seller.
      UPDATE games_players
      SET    delta_cash      = delta_cash      + (v_exec_price * v_exec_qty),
             delta_envelopes = delta_envelopes - v_exec_qty
      WHERE  map_game_id  = v_order.game_id
        AND  map_player_id = v_resting.created_by_player_id;
    ELSE
      -- Incoming order is the seller.
      UPDATE games_players
      SET    delta_cash      = delta_cash      + (v_exec_price * v_exec_qty),
             delta_envelopes = delta_envelopes - v_exec_qty
      WHERE  map_game_id  = v_order.game_id
        AND  map_player_id = v_order.created_by_player_id;

      -- Resting order is the buyer.
      UPDATE games_players
      SET    delta_cash      = delta_cash      - (v_exec_price * v_exec_qty),
             delta_envelopes = delta_envelopes + v_exec_qty
      WHERE  map_game_id  = v_order.game_id
        AND  map_player_id = v_resting.created_by_player_id;
    END IF;

    v_last_exec_price := v_exec_price;
    v_exec_count      := v_exec_count + 1;
  END LOOP;

  CLOSE v_cursor;

  -- ---- Finalise incoming order status ------------------------------------- --
  IF v_order.quantity_current = 0 THEN
    -- Fully filled (all types).
    UPDATE orders SET status = 'order_closed'  WHERE order_id = p_order_id;
  ELSIF v_order.type IN ('limit_buy', 'limit_sell') THEN
    -- Limit order with remaining quantity: add to resting book.
    UPDATE orders SET status = 'order_resting' WHERE order_id = p_order_id;
  ELSE
    -- Market order with remaining quantity: no resting for market orders.
    UPDATE orders SET status = 'order_closed'  WHERE order_id = p_order_id;
  END IF;

  -- ---- Single state_version bump ----------------------------------------- --
  -- last_traded_price updated only when at least one execution occurred.
  IF v_exec_count > 0 THEN
    UPDATE games
    SET    last_traded_price = v_last_exec_price,
           state_version     = state_version + 1
    WHERE  game_id = v_order.game_id;
  ELSE
    UPDATE games
    SET    state_version = state_version + 1
    WHERE  game_id = v_order.game_id;
  END IF;
END;
$$;

REVOKE ALL   ON FUNCTION public.match_order(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.match_order(uuid) TO service_role;


-- ============================================================================
-- process_create_order
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_create_order(p_command_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_cmd          commands%ROWTYPE;
  v_game         games%ROWTYPE;
  v_caller_row   games_players%ROWTYPE;
  v_type_raw     text;
  v_order_type   order_type;
  v_qty_raw      text;
  v_qty          integer;
  v_price_raw    text;
  v_price        numeric;
  v_order_id     uuid;
BEGIN
  -- ---- Prologue: validate command row ------------------------------------- --
  SELECT * INTO v_cmd FROM commands WHERE command_id = p_command_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_create_order: command % not found', p_command_id
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_type <> 'create_order' THEN
    RAISE EXCEPTION 'process_create_order: command % has type % (expected create_order)',
      p_command_id, v_cmd.command_type USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.command_game_id IS NULL THEN
    RAISE EXCEPTION 'process_create_order: command_game_id required'
      USING ERRCODE = 'UE001';
  END IF;
  IF v_cmd.player_id IS NULL THEN
    RAISE EXCEPTION 'process_create_order: player_id required'
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- Validate payload before touching the game row --------------------- --
  -- Fail fast on malformed payload so the UE001 error is clear.
  IF v_cmd.payload IS NULL OR jsonb_typeof(v_cmd.payload) <> 'object' THEN
    RAISE EXCEPTION 'process_create_order: payload must be a JSON object'
      USING ERRCODE = 'UE001';
  END IF;

  -- --- payload.type (order_type enum) ---
  v_type_raw := v_cmd.payload ->> 'type';
  IF v_type_raw IS NULL THEN
    RAISE EXCEPTION 'process_create_order: payload.type required'
      USING ERRCODE = 'UE001';
  END IF;
  BEGIN
    v_order_type := v_type_raw::order_type;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_create_order: payload.type is not a valid order_type (got %)',
      v_type_raw USING ERRCODE = 'UE001';
  END;

  -- --- payload.quantity_initial (positive integer) ---
  v_qty_raw := v_cmd.payload ->> 'quantity_initial';
  IF v_qty_raw IS NULL THEN
    RAISE EXCEPTION 'process_create_order: payload.quantity_initial required'
      USING ERRCODE = 'UE001';
  END IF;
  BEGIN
    v_qty := v_qty_raw::integer;
  EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'process_create_order: payload.quantity_initial is not an integer (got %)',
      v_qty_raw USING ERRCODE = 'UE001';
  END;
  IF v_qty <= 0 THEN
    RAISE EXCEPTION 'process_create_order: payload.quantity_initial must be > 0 (got %)',
      v_qty USING ERRCODE = 'UE001';
  END IF;

  -- --- payload.price_per_stock (limit: required positive numeric; market: must be absent) ---
  v_price_raw := v_cmd.payload ->> 'price_per_stock';
  IF v_order_type IN ('limit_buy', 'limit_sell') THEN
    IF v_price_raw IS NULL THEN
      RAISE EXCEPTION 'process_create_order: payload.price_per_stock required for limit orders'
        USING ERRCODE = 'UE001';
    END IF;
    BEGIN
      v_price := v_price_raw::numeric;
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'process_create_order: payload.price_per_stock is not numeric (got %)',
        v_price_raw USING ERRCODE = 'UE001';
    END;
    IF v_price <= 0 THEN
      RAISE EXCEPTION 'process_create_order: payload.price_per_stock must be > 0 for limit orders (got %)',
        v_price USING ERRCODE = 'UE001';
    END IF;
  ELSE
    -- Market order: price_per_stock must not be supplied.
    IF v_price_raw IS NOT NULL THEN
      RAISE EXCEPTION 'process_create_order: payload.price_per_stock must be absent for market orders'
        USING ERRCODE = 'UE001';
    END IF;
    v_price := NULL;
  END IF;

  -- ---- Lock game row ------------------------------------------------------- --
  SELECT * INTO v_game FROM games WHERE game_id = v_cmd.command_game_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_create_order: game % not found', v_cmd.command_game_id
      USING ERRCODE = 'UE001';
  END IF;

  -- ---- State check --------------------------------------------------------- --
  IF v_game.game_state <> 'trading_started' THEN
    RAISE EXCEPTION 'process_create_order: game_state % does not allow orders (expected trading_started)',
      v_game.game_state USING ERRCODE = 'UE002';
  END IF;

  -- ---- Player membership check -------------------------------------------- --
  SELECT * INTO v_caller_row
  FROM   games_players
  WHERE  map_game_id  = v_cmd.command_game_id
    AND  map_player_id = v_cmd.player_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'process_create_order: player % not in game %',
      v_cmd.player_id, v_cmd.command_game_id USING ERRCODE = 'UE002';
  END IF;

  -- ---- Insert order row (status = being_processed) ------------------------ --
  -- The order row does not exist until this point (PRD: created only when the
  -- command processor picks up the command, not when the user submits it).
  INSERT INTO orders (
    created_by_player_id,
    game_id,
    type,
    quantity_initial,
    quantity_current,
    price_per_stock,
    status
  ) VALUES (
    v_cmd.player_id,
    v_cmd.command_game_id,
    v_order_type,
    v_qty,
    v_qty,            -- quantity_current starts equal to quantity_initial
    v_price,
    'being_processed'
  ) RETURNING order_id INTO v_order_id;

  -- ---- Delegate to matching engine ---------------------------------------- --
  -- match_order handles: book scan, executions, delta updates,
  -- incoming order finalisation, and the single state_version bump.
  PERFORM match_order(v_order_id);
END;
$$;

REVOKE ALL   ON FUNCTION public.process_create_order(uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.process_create_order(uuid) TO service_role;
