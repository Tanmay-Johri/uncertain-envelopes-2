-- ============================================================================
-- Test: order_matching_test
-- Stream A / A6-TEST: process_create_order + match_order
--
-- Strategy:
--   * Three players: alice6 (admin/buyer/seller), bob6, carol6.
--   * One game per test scenario group to prevent order-book cross-
--     contamination and keep delta_cash/delta_envelopes starting at 0.
--   * Resting orders are inserted directly (status='order_resting')
--     rather than going through process_create_order — this lets us
--     focus each test on the specific matching behaviour being asserted.
--   * Incoming orders are always submitted via process_create_order
--     (via a command INSERT) to test the full public path.
--   * Error paths use the standard BEGIN…EXCEPTION WHEN SQLSTATE pattern.
--   * Everything is wrapped in BEGIN / ROLLBACK — no persistent side-effects.
--
-- Test sections:
--   1. Limit buy happy paths  (L1–L5)
--   2. Limit sell happy paths (S1–S3)
--   3. Market buy happy paths (M1–M3)
--   4. Market sell happy paths (N1–N3)
--   5. Priority tests          (P1–P3)
--   6. Correctness invariants  (I1–I4)
--   7. Adversarial error cases (E1–E10)
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Seed: auth users + players
-- (distinct UUIDs from prior test files to avoid conflicts)
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  ('aa666666-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'alice@a6.test'),
  ('bb666666-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bob@a6.test'),
  ('cc666666-cccc-cccc-cccc-cccccccccccc', 'carol@a6.test');

INSERT INTO players (player_id, username, email) VALUES
  ('aa666666-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'alice6', 'alice@a6.test'),
  ('bb666666-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bob6',   'bob@a6.test'),
  ('cc666666-cccc-cccc-cccc-cccccccccccc', 'carol6', 'carol@a6.test');

DO $a6_test$
DECLARE
  -- Player IDs
  v_alice  uuid := 'aa666666-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_bob    uuid := 'bb666666-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_carol  uuid := 'cc666666-cccc-cccc-cccc-cccccccccccc';

  -- Game IDs — one per scenario group
  v_g_l1  uuid;   -- limit buy exact fill
  v_g_l2  uuid;   -- limit buy partial (buy fills, sell remainder rests)
  v_g_l3  uuid;   -- limit buy partial (buy remainder rests, sell fills)
  v_g_l4  uuid;   -- limit buy multi-leg walk
  v_g_l5  uuid;   -- limit buy no match
  v_g_s1  uuid;   -- limit sell exact fill
  v_g_s2  uuid;   -- limit sell partial fill
  v_g_s3  uuid;   -- limit sell multi-leg walk
  v_g_m1  uuid;   -- market buy exact fill
  v_g_m2  uuid;   -- market buy partial (remainder closed)
  v_g_m3  uuid;   -- market buy no resting sells
  v_g_n1  uuid;   -- market sell exact fill
  v_g_n2  uuid;   -- market sell partial (remainder closed)
  v_g_n3  uuid;   -- market sell no resting buys
  v_g_p1  uuid;   -- price priority: buy side
  v_g_p2  uuid;   -- price priority: sell side
  v_g_p3  uuid;   -- FIFO tie-break
  v_g_i1  uuid;   -- invariant: exec price = resting price
  v_g_i2  uuid;   -- invariant: delta math
  v_g_i3  uuid;   -- invariant: last_traded_price tracking
  v_g_i4  uuid;   -- invariant: state_version single bump
  v_g_err uuid;   -- error cases (created state for wrong-state test)

  -- Working variables
  v_cmd_id     uuid;
  v_order_id   uuid;
  v_count      integer;
  v_status     text;
  v_qty        integer;
  v_price      numeric;
  v_ver_before integer;
  v_ver_after  integer;
  v_dc_alice   numeric;
  v_de_alice   integer;
  v_dc_bob     numeric;
  v_de_bob     integer;
  v_dc_carol   numeric;
  v_de_carol   integer;

  -- Helper: insert a game directly in 'trading_started' state
  -- (endless, 3-player max, alice as admin)
BEGIN

  -- =========================================================================
  -- Build all games upfront
  -- =========================================================================

  -- Macro-like helper: insert a trading_started endless game with alice admin
  -- and return its game_id. We inline the INSERT for each game because
  -- PL/pgSQL doesn't have macros; each needs a unique joining_code.

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-L1','public','casual',10,'LB001','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_l1;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-L2','public','casual',10,'LB002','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_l2;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-L3','public','casual',10,'LB003','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_l3;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-L4','public','casual',10,'LB004','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_l4;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-L5','public','casual',10,'LB005','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_l5;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-S1','public','casual',10,'LS001','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_s1;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-S2','public','casual',10,'LS002','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_s2;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-S3','public','casual',10,'LS003','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_s3;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-M1','public','casual',10,'MB001','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_m1;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-M2','public','casual',10,'MB002','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_m2;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-M3','public','casual',10,'MB003','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_m3;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-N1','public','casual',10,'MS001','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_n1;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-N2','public','casual',10,'MS002','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_n2;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-N3','public','casual',10,'MS003','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_n3;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-P1','public','casual',10,'PP001','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_p1;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-P2','public','casual',10,'PP002','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_p2;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-P3','public','casual',10,'PP003','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_p3;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-I1','public','casual',10,'IV001','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_i1;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-I2','public','casual',10,'IV002','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_i2;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-I3','public','casual',10,'IV003','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_i3;

  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id,
                     start_time)
  VALUES ('A6-I4','public','casual',10,'IV004','endless','trading_started',v_alice,clock_timestamp())
  RETURNING game_id INTO v_g_i4;

  -- Error game: starts in 'created' (needed for wrong-state test)
  INSERT INTO games (game_name, game_security, is_ranked, game_max_players,
                     joining_code, end_condition, game_state, admin_player_id)
  VALUES ('A6-ERR','public','casual',10,'ER001','endless','created',v_alice)
  RETURNING game_id INTO v_g_err;

  -- =========================================================================
  -- Populate games_players for all games
  -- (alice = admin, bob = member, carol = member where needed)
  -- =========================================================================
  INSERT INTO games_players (map_game_id, map_player_id, is_admin) VALUES
    -- Limit buy games
    (v_g_l1, v_alice, true),  (v_g_l1, v_bob, false),
    (v_g_l2, v_alice, true),  (v_g_l2, v_bob, false),
    (v_g_l3, v_alice, true),  (v_g_l3, v_bob, false),
    (v_g_l4, v_alice, true),  (v_g_l4, v_bob, false), (v_g_l4, v_carol, false),
    (v_g_l5, v_alice, true),  (v_g_l5, v_bob, false),
    -- Limit sell games
    (v_g_s1, v_alice, true),  (v_g_s1, v_bob, false),
    (v_g_s2, v_alice, true),  (v_g_s2, v_bob, false),
    (v_g_s3, v_alice, true),  (v_g_s3, v_bob, false), (v_g_s3, v_carol, false),
    -- Market buy games
    (v_g_m1, v_alice, true),  (v_g_m1, v_bob, false),
    (v_g_m2, v_alice, true),  (v_g_m2, v_bob, false),
    (v_g_m3, v_alice, true),
    -- Market sell games
    (v_g_n1, v_alice, true),  (v_g_n1, v_bob, false),
    (v_g_n2, v_alice, true),  (v_g_n2, v_bob, false),
    (v_g_n3, v_alice, true),
    -- Priority games
    (v_g_p1, v_alice, true),  (v_g_p1, v_bob, false), (v_g_p1, v_carol, false),
    (v_g_p2, v_alice, true),  (v_g_p2, v_bob, false), (v_g_p2, v_carol, false),
    (v_g_p3, v_alice, true),  (v_g_p3, v_bob, false), (v_g_p3, v_carol, false),
    -- Invariant games
    (v_g_i1, v_alice, true),  (v_g_i1, v_bob, false),
    (v_g_i2, v_alice, true),  (v_g_i2, v_bob, false), (v_g_i2, v_carol, false),
    (v_g_i3, v_alice, true),  (v_g_i3, v_bob, false), (v_g_i3, v_carol, false),
    (v_g_i4, v_alice, true),  (v_g_i4, v_bob, false), (v_g_i4, v_carol, false),
    -- Error game
    (v_g_err, v_alice, true), (v_g_err, v_bob, false);

  -- =========================================================================
  -- SECTION 1: Limit buy happy paths
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- L1: limit_buy qty=5 price=100 vs resting limit_sell qty=5 price=100
  --     Expected: exact fill — both order_closed, 1 execution at price=100
  -- -------------------------------------------------------------------------
  -- Seed resting sell (bob)
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_l1, 'limit_sell', 5, 5, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  -- Submit incoming buy via command
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_l1, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  -- Assertions
  SELECT status INTO v_status FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_closed',
    format('L1: bob resting sell expected order_closed, got %s', v_status);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_l1;
  ASSERT v_status = 'order_closed',
    format('L1: alice incoming buy expected order_closed, got %s', v_status);
  ASSERT v_qty = 0,
    format('L1: alice incoming buy qty_current expected 0, got %s', v_qty);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_l1;
  ASSERT v_count = 1, format('L1: expected 1 execution, got %s', v_count);

  SELECT execution_price, quantity INTO v_price, v_qty
  FROM executions WHERE executions_game_id = v_g_l1;
  ASSERT v_price = 100,  format('L1: execution price expected 100, got %s', v_price);
  ASSERT v_qty   = 5,    format('L1: execution qty expected 5, got %s', v_qty);

  SELECT delta_cash, delta_envelopes INTO v_dc_alice, v_de_alice
  FROM games_players WHERE map_game_id = v_g_l1 AND map_player_id = v_alice;
  ASSERT v_dc_alice = -500, format('L1: alice delta_cash expected -500, got %s', v_dc_alice);
  ASSERT v_de_alice = 5,    format('L1: alice delta_envelopes expected 5, got %s', v_de_alice);

  SELECT delta_cash, delta_envelopes INTO v_dc_bob, v_de_bob
  FROM games_players WHERE map_game_id = v_g_l1 AND map_player_id = v_bob;
  ASSERT v_dc_bob = 500,  format('L1: bob delta_cash expected 500, got %s', v_dc_bob);
  ASSERT v_de_bob = -5,   format('L1: bob delta_envelopes expected -5, got %s', v_de_bob);

  -- -------------------------------------------------------------------------
  -- L2: limit_buy qty=3 price=100 vs resting limit_sell qty=5 price=100
  --     Expected: buy fills completely (order_closed), sell partially filled
  --               (order_resting with qty_current=2)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_l2, 'limit_sell', 5, 5, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_l2, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',3,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_resting',
    format('L2: bob resting sell expected order_resting after partial fill, got %s', v_status);
  ASSERT v_qty = 2, format('L2: bob resting sell qty expected 2, got %s', v_qty);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_l2;
  ASSERT v_status = 'order_closed',
    format('L2: alice incoming buy expected order_closed, got %s', v_status);
  ASSERT v_qty = 0, format('L2: alice buy qty expected 0, got %s', v_qty);

  -- -------------------------------------------------------------------------
  -- L3: limit_buy qty=5 price=100 vs resting limit_sell qty=3 price=100
  --     Expected: sell fills completely (order_closed), buy partially filled
  --               (order_resting with qty_current=2)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_l3, 'limit_sell', 3, 3, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_l3, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status INTO v_status FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_closed',
    format('L3: bob resting sell expected order_closed, got %s', v_status);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_l3;
  ASSERT v_status = 'order_resting',
    format('L3: alice buy expected order_resting (partial fill remainder), got %s', v_status);
  ASSERT v_qty = 2, format('L3: alice buy remainder qty expected 2, got %s', v_qty);

  -- -------------------------------------------------------------------------
  -- L4: limit_buy qty=10 price=100 walks 3 resting sells
  --     Book: bob sells 3@90, carol sells 3@95, bob sells 3@100
  --     Expected: 3 executions at 90,95,100; buy rests qty=1
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status, order_created_at)
  VALUES
    (v_bob,   v_g_l4, 'limit_sell', 3, 3,  90, 'order_resting', clock_timestamp() - interval '3 seconds'),
    (v_carol, v_g_l4, 'limit_sell', 3, 3,  95, 'order_resting', clock_timestamp() - interval '2 seconds'),
    (v_bob,   v_g_l4, 'limit_sell', 3, 3, 100, 'order_resting', clock_timestamp() - interval '1 second');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_l4, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',10,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_l4;
  ASSERT v_count = 3, format('L4: expected 3 executions, got %s', v_count);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_l4;
  ASSERT v_status = 'order_resting',
    format('L4: alice buy expected order_resting (1 unit unmatched), got %s', v_status);
  ASSERT v_qty = 1, format('L4: alice buy remainder expected 1, got %s', v_qty);

  -- All 3 resting sells should be order_closed (each qty=3 fully consumed)
  SELECT COUNT(*) INTO v_count FROM orders
  WHERE game_id = v_g_l4 AND status = 'order_closed'
    AND type = 'limit_sell' AND created_by_player_id IN (v_bob, v_carol);
  ASSERT v_count = 3, format('L4: expected all 3 resting sells order_closed, got %s', v_count);

  -- Delta check for alice: paid 90*3 + 95*3 + 100*3 = 855; received 9 envelopes
  SELECT delta_cash, delta_envelopes INTO v_dc_alice, v_de_alice
  FROM games_players WHERE map_game_id = v_g_l4 AND map_player_id = v_alice;
  ASSERT v_dc_alice = -855, format('L4: alice delta_cash expected -855, got %s', v_dc_alice);
  ASSERT v_de_alice = 9,    format('L4: alice delta_envelopes expected 9, got %s', v_de_alice);

  -- -------------------------------------------------------------------------
  -- L5: limit_buy qty=5 price=90 with only resting sell at price=100
  --     Price doesn't cross — no match. Buy goes to order_resting.
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_l5, 'limit_sell', 5, 5, 100, 'order_resting');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_l5, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',90))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_l5;
  ASSERT v_status = 'order_resting',
    format('L5: alice buy expected order_resting (no price cross), got %s', v_status);
  ASSERT v_qty = 5, format('L5: alice buy qty should be unchanged at 5, got %s', v_qty);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_l5;
  ASSERT v_count = 0, format('L5: expected 0 executions, got %s', v_count);

  -- Bob's sell should remain untouched
  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_bob AND game_id = v_g_l5;
  ASSERT v_status = 'order_resting', format('L5: bob sell should remain order_resting, got %s', v_status);
  ASSERT v_qty = 5, format('L5: bob sell qty should remain 5, got %s', v_qty);

  -- state_version still bumped (even with 0 executions)
  SELECT state_version INTO v_ver_after FROM games WHERE game_id = v_g_l5;
  ASSERT v_ver_after = 2, format('L5: state_version expected 2 after no-match, got %s', v_ver_after);


  -- =========================================================================
  -- SECTION 2: Limit sell happy paths
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- S1: limit_sell qty=5 price=100 vs resting limit_buy qty=5 price=100
  --     Expected: exact fill — both order_closed, 1 execution at price=100
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_s1, 'limit_buy', 5, 5, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_s1, 'create_order', v_alice,
    jsonb_build_object('type','limit_sell','quantity_initial',5,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status INTO v_status FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_closed', format('S1: bob resting buy expected order_closed, got %s', v_status);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_s1;
  ASSERT v_status = 'order_closed', format('S1: alice sell expected order_closed, got %s', v_status);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_s1;
  ASSERT v_count = 1, format('S1: expected 1 execution, got %s', v_count);

  -- Alice is the seller: cash increases, envelopes decrease
  SELECT delta_cash, delta_envelopes INTO v_dc_alice, v_de_alice
  FROM games_players WHERE map_game_id = v_g_s1 AND map_player_id = v_alice;
  ASSERT v_dc_alice = 500,  format('S1: alice delta_cash expected +500, got %s', v_dc_alice);
  ASSERT v_de_alice = -5,   format('S1: alice delta_envelopes expected -5, got %s', v_de_alice);

  SELECT delta_cash, delta_envelopes INTO v_dc_bob, v_de_bob
  FROM games_players WHERE map_game_id = v_g_s1 AND map_player_id = v_bob;
  ASSERT v_dc_bob = -500, format('S1: bob delta_cash expected -500, got %s', v_dc_bob);
  ASSERT v_de_bob = 5,    format('S1: bob delta_envelopes expected +5, got %s', v_de_bob);

  -- -------------------------------------------------------------------------
  -- S2: limit_sell qty=3 price=100 vs resting limit_buy qty=5 price=100
  --     Expected: sell fills completely, buy partially filled (qty=2 resting)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_s2, 'limit_buy', 5, 5, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_s2, 'create_order', v_alice,
    jsonb_build_object('type','limit_sell','quantity_initial',3,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status, quantity_current INTO v_status, v_qty FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_resting', format('S2: bob buy expected order_resting, got %s', v_status);
  ASSERT v_qty = 2, format('S2: bob buy remaining qty expected 2, got %s', v_qty);

  SELECT status INTO v_status FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_s2;
  ASSERT v_status = 'order_closed', format('S2: alice sell expected order_closed, got %s', v_status);

  -- -------------------------------------------------------------------------
  -- S3: limit_sell qty=10 price=90 walks 2 resting buys (price 100, 95)
  --     Expected: 2 executions at 100 then 95; sell rests qty=4
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status, order_created_at)
  VALUES
    (v_bob,   v_g_s3, 'limit_buy', 3, 3, 100, 'order_resting', clock_timestamp() - interval '2 seconds'),
    (v_carol, v_g_s3, 'limit_buy', 3, 3,  95, 'order_resting', clock_timestamp() - interval '1 second');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_s3, 'create_order', v_alice,
    jsonb_build_object('type','limit_sell','quantity_initial',10,'price_per_stock',90))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_s3;
  ASSERT v_count = 2, format('S3: expected 2 executions, got %s', v_count);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_s3;
  ASSERT v_status = 'order_resting', format('S3: alice sell expected order_resting, got %s', v_status);
  ASSERT v_qty = 4, format('S3: alice sell remainder expected 4, got %s', v_qty);

  SELECT delta_cash, delta_envelopes INTO v_dc_alice, v_de_alice
  FROM games_players WHERE map_game_id = v_g_s3 AND map_player_id = v_alice;
  -- Alice sold 3@100 + 3@95 = 300+285 = 585 cash, gave 6 envelopes
  ASSERT v_dc_alice = 585, format('S3: alice delta_cash expected 585, got %s', v_dc_alice);
  ASSERT v_de_alice = -6,  format('S3: alice delta_envelopes expected -6, got %s', v_de_alice);


  -- =========================================================================
  -- SECTION 3: Market buy happy paths
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- M1: market_buy qty=5 vs resting limit_sell qty=5 price=100
  --     Expected: exact fill — both order_closed, 1 execution at price=100
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_m1, 'limit_sell', 5, 5, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_m1, 'create_order', v_alice,
    jsonb_build_object('type','market_buy','quantity_initial',5))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status INTO v_status FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_closed', format('M1: bob resting sell expected order_closed, got %s', v_status);

  SELECT status INTO v_status FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_m1;
  ASSERT v_status = 'order_closed', format('M1: alice market buy expected order_closed, got %s', v_status);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_m1;
  ASSERT v_count = 1, format('M1: expected 1 execution, got %s', v_count);

  -- -------------------------------------------------------------------------
  -- M2: market_buy qty=5 vs resting limit_sell qty=3 price=100
  --     Expected: 1 execution (qty=3); market buy gets order_closed (remainder
  --               NOT resting — market orders never rest)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_m2, 'limit_sell', 3, 3, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_m2, 'create_order', v_alice,
    jsonb_build_object('type','market_buy','quantity_initial',5))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status INTO v_status FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_closed', format('M2: bob resting sell expected order_closed, got %s', v_status);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_m2;
  ASSERT v_status = 'order_closed',
    format('M2: alice market buy expected order_closed (not resting), got %s', v_status);
  ASSERT v_qty = 2,
    format('M2: alice market buy qty_current should be 2 (unmatched remainder), got %s', v_qty);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_m2;
  ASSERT v_count = 1, format('M2: expected 1 execution (3 units), got %s', v_count);

  -- -------------------------------------------------------------------------
  -- M3: market_buy qty=5 with NO resting sells
  --     Expected: immediate order_closed, 0 executions
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_m3, 'create_order', v_alice,
    jsonb_build_object('type','market_buy','quantity_initial',5))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_m3;
  ASSERT v_status = 'order_closed',
    format('M3: alice market buy expected order_closed (no book), got %s', v_status);
  ASSERT v_qty = 5,
    format('M3: alice market buy qty should remain 5 (nothing matched), got %s', v_qty);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_m3;
  ASSERT v_count = 0, format('M3: expected 0 executions, got %s', v_count);


  -- =========================================================================
  -- SECTION 4: Market sell happy paths
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- N1: market_sell qty=5 vs resting limit_buy qty=5 price=100
  --     Expected: exact fill — both order_closed, 1 execution at price=100
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_n1, 'limit_buy', 5, 5, 100, 'order_resting')
  RETURNING order_id INTO v_order_id;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_n1, 'create_order', v_alice,
    jsonb_build_object('type','market_sell','quantity_initial',5))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status INTO v_status FROM orders WHERE order_id = v_order_id;
  ASSERT v_status = 'order_closed', format('N1: bob resting buy expected order_closed, got %s', v_status);
  SELECT status INTO v_status FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_n1;
  ASSERT v_status = 'order_closed', format('N1: alice market sell expected order_closed, got %s', v_status);

  -- -------------------------------------------------------------------------
  -- N2: market_sell qty=5 vs resting limit_buy qty=3 price=100
  --     Expected: partial fill; market sell gets order_closed (not resting)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_n2, 'limit_buy', 3, 3, 100, 'order_resting');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_n2, 'create_order', v_alice,
    jsonb_build_object('type','market_sell','quantity_initial',5))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status, quantity_current INTO v_status, v_qty
  FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_n2;
  ASSERT v_status = 'order_closed',
    format('N2: alice market sell expected order_closed (remainder not resting), got %s', v_status);
  ASSERT v_qty = 2,
    format('N2: alice market sell qty_current should be 2, got %s', v_qty);

  -- -------------------------------------------------------------------------
  -- N3: market_sell qty=5 with NO resting buys
  --     Expected: immediate order_closed, 0 executions
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_n3, 'create_order', v_alice,
    jsonb_build_object('type','market_sell','quantity_initial',5))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT status INTO v_status FROM orders WHERE created_by_player_id = v_alice AND game_id = v_g_n3;
  ASSERT v_status = 'order_closed',
    format('N3: alice market sell expected order_closed (empty book), got %s', v_status);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_n3;
  ASSERT v_count = 0, format('N3: expected 0 executions, got %s', v_count);


  -- =========================================================================
  -- SECTION 5: Priority tests
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- P1: Price priority — buy side
  --     Book: bob has limit_sell qty=5 price=95; carol has limit_sell qty=5 price=100
  --     Incoming: alice limit_buy qty=5 price=100
  --     Expected: matched against bob (cheaper sell at 95) first.
  --               carol's sell remains order_resting.
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES
    (v_bob,   v_g_p1, 'limit_sell', 5, 5,  95, 'order_resting'),
    (v_carol, v_g_p1, 'limit_sell', 5, 5, 100, 'order_resting');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_p1, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_p1;
  ASSERT v_count = 1, format('P1: expected 1 execution (price priority), got %s', v_count);

  SELECT execution_price INTO v_price FROM executions WHERE executions_game_id = v_g_p1;
  ASSERT v_price = 95, format('P1: execution should be at bob price=95 (cheaper first), got %s', v_price);

  -- Carol's sell should be untouched
  SELECT status INTO v_status FROM orders
  WHERE game_id = v_g_p1 AND created_by_player_id = v_carol;
  ASSERT v_status = 'order_resting', format('P1: carol sell should remain order_resting, got %s', v_status);

  -- -------------------------------------------------------------------------
  -- P2: Price priority — sell side
  --     Book: bob has limit_buy qty=5 price=100; carol has limit_buy qty=5 price=95
  --     Incoming: alice limit_sell qty=5 price=95
  --     Expected: matched against bob (higher buy at 100) first.
  --               carol's buy remains order_resting.
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES
    (v_bob,   v_g_p2, 'limit_buy', 5, 5, 100, 'order_resting'),
    (v_carol, v_g_p2, 'limit_buy', 5, 5,  95, 'order_resting');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_p2, 'create_order', v_alice,
    jsonb_build_object('type','limit_sell','quantity_initial',5,'price_per_stock',95))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT execution_price INTO v_price FROM executions WHERE executions_game_id = v_g_p2;
  ASSERT v_price = 100, format('P2: execution should be at bob price=100 (higher first), got %s', v_price);

  SELECT status INTO v_status FROM orders
  WHERE game_id = v_g_p2 AND created_by_player_id = v_carol;
  ASSERT v_status = 'order_resting', format('P2: carol buy should remain order_resting, got %s', v_status);

  -- -------------------------------------------------------------------------
  -- P3: FIFO tie-break — two resting sells at same price, different timestamps
  --     Book: bob limit_sell qty=5 price=100 (earlier); carol limit_sell qty=5 price=100 (later)
  --     Incoming: alice limit_buy qty=5 price=100
  --     Expected: matched against bob (earlier timestamp) first. Carol untouched.
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status, order_created_at)
  VALUES
    (v_bob,   v_g_p3, 'limit_sell', 5, 5, 100, 'order_resting', clock_timestamp() - interval '5 seconds'),
    (v_carol, v_g_p3, 'limit_sell', 5, 5, 100, 'order_resting', clock_timestamp() - interval '1 second');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_p3, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',100))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  -- Exactly 1 execution and it was against bob's order
  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_p3;
  ASSERT v_count = 1, format('P3: expected 1 execution (FIFO), got %s', v_count);

  SELECT status INTO v_status FROM orders
  WHERE game_id = v_g_p3 AND created_by_player_id = v_bob AND type = 'limit_sell';
  ASSERT v_status = 'order_closed',
    format('P3: bob (earlier) sell should be order_closed, got %s', v_status);

  SELECT status INTO v_status FROM orders
  WHERE game_id = v_g_p3 AND created_by_player_id = v_carol AND type = 'limit_sell';
  ASSERT v_status = 'order_resting',
    format('P3: carol (later) sell should remain order_resting, got %s', v_status);


  -- =========================================================================
  -- SECTION 6: Correctness invariants
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- I1: Execution price = resting order price (not incoming order price)
  --     Resting: bob limit_sell qty=5 price=40
  --     Incoming: alice limit_buy qty=5 price=50 (willing to pay up to 50)
  --     Expected: execution_price = 40 (resting price, NOT 50)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
  VALUES (v_bob, v_g_i1, 'limit_sell', 5, 5, 40, 'order_resting');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_i1, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',50))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT execution_price INTO v_price FROM executions WHERE executions_game_id = v_g_i1;
  ASSERT v_price = 40,
    format('I1: execution price must equal resting order price=40, not incoming=50. Got %s', v_price);

  -- Alice paid 40 per unit (resting price), not 50
  SELECT delta_cash INTO v_dc_alice FROM games_players
  WHERE map_game_id = v_g_i1 AND map_player_id = v_alice;
  ASSERT v_dc_alice = -200,
    format('I1: alice delta_cash expected -200 (5 * 40, not 5 * 50), got %s', v_dc_alice);

  -- -------------------------------------------------------------------------
  -- I2: Delta math correct after multi-leg match
  --     Book: bob limit_sell qty=3 price=30; carol limit_sell qty=3 price=35
  --     Incoming: alice limit_buy qty=6 price=40
  --     Expected:
  --       alice: delta_cash = -(30*3 + 35*3) = -195; delta_envelopes = +6
  --       bob:   delta_cash = +90;  delta_envelopes = -3
  --       carol: delta_cash = +105; delta_envelopes = -3
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status, order_created_at)
  VALUES
    (v_bob,   v_g_i2, 'limit_sell', 3, 3, 30, 'order_resting', clock_timestamp() - interval '2 seconds'),
    (v_carol, v_g_i2, 'limit_sell', 3, 3, 35, 'order_resting', clock_timestamp() - interval '1 second');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_i2, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',6,'price_per_stock',40))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT delta_cash, delta_envelopes INTO v_dc_alice, v_de_alice
  FROM games_players WHERE map_game_id = v_g_i2 AND map_player_id = v_alice;
  ASSERT v_dc_alice = -195, format('I2: alice delta_cash expected -195, got %s', v_dc_alice);
  ASSERT v_de_alice = 6,    format('I2: alice delta_envelopes expected 6, got %s', v_de_alice);

  SELECT delta_cash, delta_envelopes INTO v_dc_bob, v_de_bob
  FROM games_players WHERE map_game_id = v_g_i2 AND map_player_id = v_bob;
  ASSERT v_dc_bob = 90,  format('I2: bob delta_cash expected 90, got %s', v_dc_bob);
  ASSERT v_de_bob = -3,  format('I2: bob delta_envelopes expected -3, got %s', v_de_bob);

  SELECT delta_cash, delta_envelopes INTO v_dc_carol, v_de_carol
  FROM games_players WHERE map_game_id = v_g_i2 AND map_player_id = v_carol;
  ASSERT v_dc_carol = 105, format('I2: carol delta_cash expected 105, got %s', v_dc_carol);
  ASSERT v_de_carol = -3,  format('I2: carol delta_envelopes expected -3, got %s', v_de_carol);

  -- -------------------------------------------------------------------------
  -- I3: last_traded_price updated to last execution's price
  --     Book: bob limit_sell qty=3 price=30; carol limit_sell qty=3 price=35
  --     Incoming: alice limit_buy qty=6 price=40 (walks both)
  --     Expected: last_traded_price = 35 (the LAST leg's price)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status, order_created_at)
  VALUES
    (v_bob,   v_g_i3, 'limit_sell', 3, 3, 30, 'order_resting', clock_timestamp() - interval '2 seconds'),
    (v_carol, v_g_i3, 'limit_sell', 3, 3, 35, 'order_resting', clock_timestamp() - interval '1 second');

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_i3, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',6,'price_per_stock',40))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT last_traded_price INTO v_price FROM games WHERE game_id = v_g_i3;
  ASSERT v_price = 35,
    format('I3: last_traded_price expected 35 (last leg price), got %s', v_price);

  -- Verify last_traded_price was NOT set to 30 (first leg) or NULL
  ASSERT v_price IS NOT NULL, 'I3: last_traded_price should not be NULL after executions';

  -- -------------------------------------------------------------------------
  -- I4: state_version bumped exactly once per process_create_order call
  --     regardless of how many execution legs are created
  --     Book: bob limit_sell qty=3 price=30; carol limit_sell qty=3 price=35
  --     Incoming: alice limit_buy qty=6 price=40 → 2 executions created
  --     Expected: state_version increases by exactly 1 (not 2)
  -- -------------------------------------------------------------------------
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status, order_created_at)
  VALUES
    (v_bob,   v_g_i4, 'limit_sell', 3, 3, 30, 'order_resting', clock_timestamp() - interval '2 seconds'),
    (v_carol, v_g_i4, 'limit_sell', 3, 3, 35, 'order_resting', clock_timestamp() - interval '1 second');

  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g_i4;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_i4, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',6,'price_per_stock',40))
  RETURNING command_id INTO v_cmd_id;
  PERFORM process_create_order(v_cmd_id);

  SELECT state_version INTO v_ver_after FROM games WHERE game_id = v_g_i4;
  ASSERT v_ver_after = v_ver_before + 1,
    format('I4: state_version expected % (one bump for 2 legs), got %s',
           v_ver_before + 1, v_ver_after);

  SELECT COUNT(*) INTO v_count FROM executions WHERE executions_game_id = v_g_i4;
  ASSERT v_count = 2, format('I4: sanity — expected 2 executions (confirming multi-leg), got %s', v_count);


  -- =========================================================================
  -- SECTION 7: Adversarial error cases for process_create_order
  -- =========================================================================
  -- We need the game in 'created' state for the wrong-game-state test (E9).
  -- All other error tests can use v_g_err after we confirm E9 first,
  -- then update it to trading_started for the player-not-in-game test (E10).

  -- -------------------------------------------------------------------------
  -- E1: command_type ≠ create_order → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'join_game', v_alice, '{}')
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E1 — expected UE001 for wrong command_type';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E2: player_id IS NULL → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', NULL,
    jsonb_build_object('type','limit_buy','quantity_initial',1,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E2 — expected UE001 for null player_id';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E3: payload.type missing → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('quantity_initial',5,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E3 — expected UE001 for missing payload.type';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E4: payload.type is invalid string → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('type','super_buy','quantity_initial',5,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E4 — expected UE001 for invalid order_type string';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E5: payload.quantity_initial = 0 → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',0,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E5 — expected UE001 for quantity_initial=0';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E6: payload.quantity_initial = -1 → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',-1,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E6 — expected UE001 for quantity_initial=-1';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E7: limit order missing price_per_stock → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E7 — expected UE001 for limit order without price';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E8: limit order price_per_stock = 0 → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('type','limit_sell','quantity_initial',5,'price_per_stock',0))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E8 — expected UE001 for price_per_stock=0';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E9: market order with price_per_stock present → UE001
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('type','market_buy','quantity_initial',5,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E9 — expected UE001 for market order with price present';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E10: game_state ≠ trading_started → UE002
  --      v_g_err is in 'created' state — valid payload, wrong game state
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_err, 'create_order', v_alice,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E10 — expected UE002 for wrong game_state (created)';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;

  -- -------------------------------------------------------------------------
  -- E11: player not in game → UE002
  --      Use v_g_l5 (trading_started) and carol who is NOT in that game
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (v_g_l5, 'create_order', v_carol,
    jsonb_build_object('type','limit_buy','quantity_initial',5,'price_per_stock',10))
  RETURNING command_id INTO v_cmd_id;

  BEGIN
    PERFORM process_create_order(v_cmd_id);
    RAISE EXCEPTION 'FAIL: E11 — expected UE002 for player not in game';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL;
  END;

  RAISE NOTICE 'A6 order matching tests: ALL PASSED';

END;
$a6_test$;

ROLLBACK;
