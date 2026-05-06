-- ============================================================================
-- Test: cancel_order_test
-- Stream A / A7-TEST: process_cancel_order
--
-- Strategy:
--   * Seed alice + bob (auth + players) with deterministic UUIDs.
--   * One primary trading_started hub game for happy paths + most errors.
--   * Extra games where needed (cross-game mismatch, wrong game_states).
--   * Commands invoke process_cancel_order directly (same pattern as the
--     other processor-bound proc tests).
--   * Wrapped in BEGIN / ROLLBACK — no persistence.
--
-- Note on E3: table CHECK forbids inserting cancel_order with NULL
-- command_game_id under normal schema. That case is exercised by temporarily
-- dropping the CHECK inside this transaction scope; outer ROLLBACK restores
-- the constraint (no manual re-add needed).
-- ============================================================================

BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('aa777777-7777-7777-7777-777777777777', 'alice@a7.test'),
  ('bb777777-7777-7777-7777-777777777777', 'bob@a7.test');

INSERT INTO players (player_id, username, email) VALUES
  ('aa777777-7777-7777-7777-777777777777', 'alice7', 'alice@a7.test'),
  ('bb777777-7777-7777-7777-777777777777', 'bob7',   'bob@a7.test');

DO $a7_test$
DECLARE
  v_alice   uuid := 'aa777777-7777-7777-7777-777777777777';
  v_bob     uuid := 'bb777777-7777-7777-7777-777777777777';

  v_g_hub   uuid;   -- trading_started alice+bob
  v_g_other uuid;   -- trading_started alice+bob (wrong-game mismatch)
  v_g_cre   uuid;   -- created
  v_g_end   uuid;   -- trading_ended
  v_g_fin   uuid;   -- game_finalised
  v_g_dis   uuid;   -- discarded

  v_cmd_id   uuid;
  v_order_id uuid;
  v_sid      uuid;
  v_ver0     integer;
  v_ver1     integer;
  v_st       order_status;
  v_qty      integer;
  v_dc       numeric;
  v_de       integer;
BEGIN

  --------------------------------------------------------------------------
  -- Build games
  --------------------------------------------------------------------------
  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id,
    start_time
  )
  VALUES ('A7 Hub','public','casual',10,'C7HUB','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_hub;

  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id,
    start_time
  )
  VALUES ('A7 Cross','public','casual',10,'C7X01','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_other;

  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id
  )
  VALUES ('A7 Created','public','casual',10,'C7CRE','endless','created',v_alice)
  RETURNING game_id INTO v_g_cre;

  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id
  )
  VALUES ('A7 TrdEnd','public','casual',10,'C7END','endless','trading_ended',v_alice)
  RETURNING game_id INTO v_g_end;

  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id
  )
  VALUES ('A7 Fin','public','casual',10,'C7FIN','endless','game_finalised',v_alice)
  RETURNING game_id INTO v_g_fin;

  INSERT INTO games (
    game_name, game_security, is_ranked, game_max_players,
    joining_code, end_condition, game_state, admin_player_id
  )
  VALUES ('A7 Dis','public','casual',10,'C7DIS','endless','discarded',v_alice)
  RETURNING game_id INTO v_g_dis;

  INSERT INTO games_players (map_game_id, map_player_id, is_admin) VALUES
    (v_g_hub,   v_alice, true),
    (v_g_hub,   v_bob, false),
    (v_g_other, v_alice, true),
    (v_g_other, v_bob, false);

  --------------------------------------------------------------------------
  -- H1: resting limit_buy — cancel, deltas unchanged (non-zero), version +1,
  --     quantity_current untouched
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 10, 10, 50::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  UPDATE games_players
  SET    delta_cash = -777.007, delta_envelopes = 42
  WHERE  map_game_id = v_g_hub AND map_player_id = v_alice;

  SELECT state_version INTO v_ver0 FROM games WHERE game_id = v_g_hub;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_cancel_order(v_cmd_id);

  SELECT status, quantity_current INTO v_st, v_qty FROM orders WHERE order_id = v_order_id;
  ASSERT v_st = 'cancelled'::order_status, format('H1: expected cancelled got %', v_st);
  ASSERT v_qty = 10, format('H1: qty unchanged exp 10 got %', v_qty);

  SELECT delta_cash, delta_envelopes INTO v_dc, v_de
  FROM games_players WHERE map_game_id = v_g_hub AND map_player_id = v_alice;
  ASSERT v_dc = -777.007, format('H1: delta_cash unchanged got %', v_dc);
  ASSERT v_de = 42, format('H1: delta_env unchanged got %', v_de);

  SELECT state_version INTO v_ver1 FROM games WHERE game_id = v_g_hub;
  ASSERT v_ver1 = v_ver0 + 1, format('H1: version % exp %', v_ver1, v_ver0 + 1);


  --------------------------------------------------------------------------
  -- H2: resting limit_sell — cancel cleanly
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_sell', 7, 7, 33::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  SELECT state_version INTO v_ver0 FROM games WHERE game_id = v_g_hub;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_cancel_order(v_cmd_id);

  SELECT status INTO v_st FROM orders WHERE order_id = v_order_id;
  ASSERT v_st = 'cancelled'::order_status, format('H2: expected cancelled got %', v_st);

  SELECT state_version INTO v_ver1 FROM games WHERE game_id = v_g_hub;
  ASSERT v_ver1 = v_ver0 + 1, format('H2: single version bump');


  --------------------------------------------------------------------------
  -- E0: command missing → UE001
  --------------------------------------------------------------------------
  BEGIN
    PERFORM process_cancel_order('11111111-2222-3333-4444-555555555555');
    RAISE EXCEPTION 'FAIL: E0 expected UE001 missing command';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E1: wrong command_type → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'join_game', v_alice, jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E1 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E2: player_id NULL → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', NULL,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E2 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E4: missing order_id in payload → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice, '{}'::jsonb)
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E4 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E5: order_id not a uuid → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id','nope-not-uuid'))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E5 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E6: order row does not exist → UE001
  --------------------------------------------------------------------------
  v_sid := 'deadbeef-dead-beef-dead-beefdeadbeef'::uuid;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_sid::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E6 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E7: order lives in hub; command cites v_g_other → UE001 mismatch
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 5, 5, 44::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_other, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E7 expected UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E8/E9/E11: non-resting status → UE002
  --------------------------------------------------------------------------

  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 2, 2, 10::numeric, 'being_processed'
  ) RETURNING order_id INTO v_order_id;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E8 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 2, 0, 10::numeric, 'order_closed'
  ) RETURNING order_id INTO v_order_id;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E9 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 2, 1, 10::numeric, 'game_ended'
  ) RETURNING order_id INTO v_order_id;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E11 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E10: already cancelled → UE002
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 3, 3, 10::numeric, 'cancelled'::order_status
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E10 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E12: bob tries to cancel alice order → UE002
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_buy', 4, 4, 20::numeric, 'order_resting'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_bob,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E12 expected UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E13–E16: wrong game_state (never touches order lookup) → UE002
  -- Payload order_id irrelevant (deterministic valid uuid placeholder).
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_cre, 'cancel_order', v_alice,
    jsonb_build_object('order_id', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E13 expected UE002 created';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_end, 'cancel_order', v_alice,
    jsonb_build_object('order_id', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E14 expected UE002 trading_ended';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_fin, 'cancel_order', v_alice,
    jsonb_build_object('order_id', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E15 expected UE002 game_finalised';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_dis, 'cancel_order', v_alice,
    jsonb_build_object('order_id', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E16 expected UE002 discarded';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E17: in_queue status → UE002
  --------------------------------------------------------------------------
  INSERT INTO orders (
    created_by_player_id, game_id, type, quantity_initial,
    quantity_current, price_per_stock, status
  ) VALUES (
    v_alice, v_g_hub, 'limit_sell', 1, 1, 55::numeric, 'in_queue'
  ) RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice,
    jsonb_build_object('order_id', v_order_id::text))
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E17 expected UE002 in_queue';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E18: payload is not an object → UE001
  --------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_hub, 'cancel_order', v_alice, '[]'::jsonb)
  RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E18 expected UE001 non-object payload';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  --------------------------------------------------------------------------
  -- E3: NULL command_game_id — drop CHECK briefly, restore, UE001 branch
  --------------------------------------------------------------------------
  ALTER TABLE commands DROP CONSTRAINT commands_game_id_required_for_non_create;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (NULL, 'cancel_order', v_alice,
    jsonb_build_object('order_id','bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::text))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_cancel_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E3 expected UE001 null command_game_id';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;


  RAISE NOTICE 'A7 cancel_order tests: ALL PASSED';
END;
$a7_test$;

ROLLBACK;
