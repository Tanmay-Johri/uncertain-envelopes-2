-- ============================================================================
-- Test: partial_cancel_order_test
-- process_partial_cancel_order
--
-- Wrapped in BEGIN / ROLLBACK — no persistence.
-- Requires migrations 018 + 019 applied (enum + function).
-- ============================================================================

BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('cc888888-8888-8888-8888-888888888888', 'alice@pc.test'),
  ('dd888888-8888-8888-8888-888888888888', 'bob@pc.test');

INSERT INTO players (player_id, username, email) VALUES
  ('cc888888-8888-8888-8888-888888888888', 'alicepc', 'alice@pc.test'),
  ('dd888888-8888-8888-8888-888888888888', 'bobpc',   'bob@pc.test');

DO $pc_test$
DECLARE
  v_alice   uuid := 'cc888888-8888-8888-8888-888888888888';
  v_bob     uuid := 'dd888888-8888-8888-8888-888888888888';

  v_g_hub   uuid;
  v_g_cre   uuid;

  v_cmd_id   uuid;
  v_order_id uuid;
  v_ver0     integer;
  v_ver1     integer;
  v_st       order_status;
  v_qty      integer;
  v_created  timestamptz;
BEGIN

  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id,
    start_time
  )
  VALUES ('PC Hub','public','casual',10,'PCHUB','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_hub;

  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id
  )
  VALUES ('PC Created','public','casual',10,'PCCRE','endless','created',v_alice)
  RETURNING game_id INTO v_g_cre;

  INSERT INTO games_players (map_game_id, map_player_id, is_admin) VALUES
    (v_g_hub, v_alice, true),
    (v_g_hub, v_bob, false);

  --------------------------------------------------------------------------
  -- H1: partial — reduces quantity_current
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 10, 10, 50::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  SELECT state_version INTO v_ver0 FROM games WHERE game_id = v_g_hub;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 3))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_partial_cancel_order(v_cmd_id);

  SELECT status, quantity_current INTO v_st, v_qty FROM orders WHERE order_id = v_order_id;
  ASSERT v_st = 'order_resting'::order_status, format('H1: status exp resting got %', v_st);
  ASSERT v_qty = 7, format('H1: qty exp 7 got %', v_qty);

  SELECT state_version INTO v_ver1 FROM games WHERE game_id = v_g_hub;
  ASSERT v_ver1 = v_ver0 + 1, format('H1: version % exp %', v_ver1, v_ver0 + 1);


  --------------------------------------------------------------------------
  -- H2: order_created_at unchanged after partial
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 8, 8, 40::numeric, 'order_resting'
  ) RETURNING order_id, order_created_at INTO v_order_id, v_created;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 2))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_partial_cancel_order(v_cmd_id);

  ASSERT (SELECT order_created_at FROM orders WHERE order_id = v_order_id) = v_created,
    'H2: order_created_at must not change';


  --------------------------------------------------------------------------
  -- H3: remainder > 0 stays resting (covered by H1); H4: qty >= current → cancelled, qty unchanged
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_sell', 5, 5, 30::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 99))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_partial_cancel_order(v_cmd_id);

  SELECT status, quantity_current INTO v_st, v_qty FROM orders WHERE order_id = v_order_id;
  ASSERT v_st = 'cancelled'::order_status, format('H4: exp cancelled got %', v_st);
  ASSERT v_qty = 5, format('H4: qty unchanged exp 5 got %', v_qty);

  --------------------------------------------------------------------------
  -- H4b: quantity_to_cancel == quantity_current → cancelled
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_sell', 4, 4, 22::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 4))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_partial_cancel_order(v_cmd_id);

  SELECT status INTO v_st FROM orders WHERE order_id = v_order_id;
  ASSERT v_st = 'cancelled'::order_status, format('H4b: exp cancelled got %', v_st);


  --------------------------------------------------------------------------
  -- H5: quantity_to_cancel = 0 → UE001
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 3, 3, 10::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 0))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_partial_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: H5 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- H5b: negative → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', -1))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_partial_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: H5b expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- H6: non-resting → UE002
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 2, 2, 11::numeric, 'in_queue'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 1))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_partial_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: H6 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- H7: state_version bump (already in H1); extra bump check after chain
  --------------------------------------------------------------------------
  SELECT state_version INTO v_ver0 FROM games WHERE game_id = v_g_hub;
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 1, 1, 9::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 1))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_partial_cancel_order(v_cmd_id);

  SELECT state_version INTO v_ver1 FROM games WHERE game_id = v_g_hub;
  ASSERT v_ver1 = v_ver0 + 1, format('H7: version bump % -> %', v_ver0, v_ver1);


  --------------------------------------------------------------------------
  -- H8: wrong game state (created) → UE002
  --------------------------------------------------------------------------
  INSERT INTO games_players (map_game_id, map_player_id, is_admin) VALUES
    (v_g_cre, v_alice, true);

  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_cre, 'limit_buy', 2, 2, 12::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_cre, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 1))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_partial_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: H8 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- H9: wrong owner → UE002
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 2, 2, 13::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_bob,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 1))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_partial_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: H9 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E1: wrong command_type → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text, 'quantity_to_cancel', 1))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_partial_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E1 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E2: missing quantity_to_cancel → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'partial_cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_partial_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E2 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  RAISE NOTICE 'partial_cancel_order tests: ALL PASSED';
END;
$pc_test$;

ROLLBACK;
