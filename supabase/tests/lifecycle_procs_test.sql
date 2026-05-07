-- ============================================================================
-- Test: lifecycle_procs_test
-- Stream A / A5-TEST: process_start_game, process_end_trading,
--   process_set_envelope_price, process_finalise_game,
--   process_discard_game, process_add_time
--
-- Strategy:
--   * Seed 3 players: alice (admin), bob (member), carol (outsider).
--   * Four test games:
--       G1 — timed 3600s, alice admin, bob member.
--            Happy-path chain: start → add_time → system-end → set_price → finalise.
--       G2 — endless, alice admin, bob member.
--            Happy-path chain: start → admin-end → discard.
--       G3 — created only, alice admin.
--            Used for: discard-from-created happy path.
--       G4 — endless, alice admin.
--            Used for: wrong-state error cases that need a started endless game.
--   * Error cases are exercised on the games above at the appropriate state,
--     or by directly UPDATEing game_state to the desired value (same technique
--     as lobby_procs_test.sql) when the happy-path chain hasn't reached that
--     state yet.
--   * Everything is wrapped in BEGIN / ROLLBACK — no persistent side-effects.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Seed
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  ('aa111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'alice@a5.test'),
  ('bb222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bob@a5.test'),
  ('cc333333-cccc-cccc-cccc-cccccccccccc', 'carol@a5.test');

INSERT INTO players (player_id, username, email) VALUES
  ('aa111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'alice5', 'alice@a5.test'),
  ('bb222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'bob5',   'bob@a5.test'),
  ('cc333333-cccc-cccc-cccc-cccccccccccc', 'carol5', 'carol@a5.test');

DO $a5_test$
DECLARE
  v_alice  uuid := 'aa111111-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_bob    uuid := 'bb222222-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_carol  uuid := 'cc333333-cccc-cccc-cccc-cccccccccccc';

  v_cmd_id        uuid;
  v_create_cmd_id uuid;
  v_g1            uuid;   -- timed 3600s, alice+bob
  v_g2            uuid;   -- endless,     alice+bob
  v_g3            uuid;   -- created only, alice
  v_g4            uuid;   -- endless,     alice (for started-endless error cases)

  v_ver_before     integer;
  v_ver_after      integer;
  v_state          text;
  v_count          integer;
  v_start_time     timestamptz;
  v_end_time_dec   timestamptz;
  v_total_secs     integer;
  v_end_time_act   timestamptz;
  v_env_price      numeric;
  v_pnl_alice      numeric;
  v_pnl_bob        numeric;
  v_ls_alice       text;
  v_ls_bob         text;
BEGIN

  -- =========================================================================
  -- Build games
  -- =========================================================================

  -- G1: timed 3600s, alice admin, bob member
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','A5 Timed','game_security','public','is_ranked','casual',
    'game_max_players',5,'end_condition','timed','total_decided_duration_seconds',3600
  )) RETURNING command_id INTO v_create_cmd_id;
  v_g1 := process_create_game(v_create_cmd_id);

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'join_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_join_game(v_cmd_id);

  -- G2: endless, alice admin, bob member
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','A5 Endless','game_security','public','is_ranked','casual',
    'game_max_players',5,'end_condition','endless'
  )) RETURNING command_id INTO v_create_cmd_id;
  v_g2 := process_create_game(v_create_cmd_id);

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g2, 'join_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_join_game(v_cmd_id);

  -- G3: created only, alice admin (bob NOT in game)
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','A5 Discard','game_security','public','is_ranked','casual',
    'game_max_players',5,'end_condition','endless'
  )) RETURNING command_id INTO v_create_cmd_id;
  v_g3 := process_create_game(v_create_cmd_id);

  -- G4: endless, alice admin (bob NOT in game)
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','A5 Err','game_security','public','is_ranked','casual',
    'game_max_players',5,'end_condition','endless'
  )) RETURNING command_id INTO v_create_cmd_id;
  v_g4 := process_create_game(v_create_cmd_id);


  -- =========================================================================
  -- process_start_game
  -- =========================================================================

  -- ---- UE001: command not found ------------------------------------------
  BEGIN
    PERFORM process_start_game('00000000-0000-0000-0000-000000000000'::uuid);
    RAISE EXCEPTION 'FAIL: start_game command not found should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: wrong command_type -----------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'join_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_start_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: start_game wrong type should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: null player_id ---------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'start_game', NULL)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_start_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: start_game null player_id should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE002: non-admin caller (bob) -------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'start_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_start_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: start_game non-admin should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: outsider caller (carol, not in game) -----------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'start_game', v_carol)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_start_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: start_game outsider should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: wrong game_state (simulate already started) ----------------
  UPDATE games SET game_state = 'trading_started', start_time = clock_timestamp()
    WHERE game_id = v_g3;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_start_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: start_game trading_started should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;
  -- Reset G3 back to created for later discard test
  UPDATE games SET game_state = 'created', start_time = NULL WHERE game_id = v_g3;

  -- ---- Happy: start G1 (timed) -------------------------------------------
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g1;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_start_game(v_cmd_id);

  SELECT game_state, state_version, start_time, end_time_decided
    INTO v_state, v_ver_after, v_start_time, v_end_time_dec
    FROM games WHERE game_id = v_g1;

  ASSERT v_state = 'trading_started',
    format('start timed: expected trading_started, got %s', v_state);
  ASSERT v_ver_after = v_ver_before + 1,
    format('start timed: state_version %s -> %s', v_ver_before, v_ver_after);
  ASSERT v_start_time IS NOT NULL,
    'start timed: start_time should be set';
  ASSERT v_end_time_dec IS NOT NULL,
    'start timed: end_time_decided should be set for timed game';
  -- end_time_decided should be approximately start_time + 3600s
  ASSERT abs(extract(epoch from (v_end_time_dec - v_start_time)) - 3600) < 1,
    format('start timed: end_time_decided offset should be ~3600s, got %s',
           extract(epoch from (v_end_time_dec - v_start_time)));

  -- ---- Happy: start G2 (endless) -----------------------------------------
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g2;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g2, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_start_game(v_cmd_id);

  SELECT game_state, end_time_decided
    INTO v_state, v_end_time_dec
    FROM games WHERE game_id = v_g2;

  ASSERT v_state = 'trading_started',
    format('start endless: expected trading_started, got %s', v_state);
  ASSERT v_end_time_dec IS NULL,
    'start endless: end_time_decided must remain NULL for endless game';

  -- ---- Happy: start G4 (endless, used later for add_time error tests) ----
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g4, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_start_game(v_cmd_id);

  -- ---- UE002: double-start G1 (already trading_started) -----------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_start_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: start_game double-start should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;


  -- =========================================================================
  -- process_add_time  (G1 is trading_started, timed, end_time_decided ~now+1h)
  -- =========================================================================

  -- ---- UE001: command not found ------------------------------------------
  BEGIN
    PERFORM process_add_time('00000000-0000-0000-0000-000000000000'::uuid);
    RAISE EXCEPTION 'FAIL: add_time command not found should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: wrong command_type -----------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time wrong type should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: null player_id ---------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'add_time', NULL)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time null player_id should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: missing additional_seconds in payload ----------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time missing additional_seconds should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: non-integer additional_seconds (float string) --------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{"additional_seconds": "60.5"}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time non-integer should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: non-integer additional_seconds (alpha string) --------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{"additional_seconds": "abc"}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time alpha string should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: zero additional_seconds ------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{"additional_seconds": 0}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time zero seconds should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: negative additional_seconds --------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{"additional_seconds": -60}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time negative seconds should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE002: endless game (G4) ------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g4, 'add_time', v_alice, '{"additional_seconds": 60}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time on endless game should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: wrong game_state (G3 is created) ---------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g3, 'add_time', v_alice, '{"additional_seconds": 60}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time on created game should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: non-admin caller -------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_bob, '{"additional_seconds": 60}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time non-admin should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: deadline already passed ------------------------------------
  -- Temporarily push end_time_decided to the past; validate proc rejects it.
  UPDATE games
    SET end_time_decided = clock_timestamp() - interval '1 minute'
    WHERE game_id = v_g1;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{"additional_seconds": 60}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_add_time(v_cmd_id);
    RAISE EXCEPTION 'FAIL: add_time past deadline should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;
  -- Restore end_time_decided to 1 hour in the future for happy-path tests
  SELECT start_time INTO v_start_time FROM games WHERE game_id = v_g1;
  UPDATE games
    SET end_time_decided = v_start_time + interval '3600 seconds'
    WHERE game_id = v_g1;

  -- ---- Happy: add 60s to G1 ----------------------------------------------
  SELECT state_version, total_decided_duration_seconds, end_time_decided
    INTO v_ver_before, v_total_secs, v_end_time_dec
    FROM games WHERE game_id = v_g1;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{"additional_seconds": 60}')
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_add_time(v_cmd_id);

  SELECT state_version, total_decided_duration_seconds, end_time_decided
    INTO v_ver_after, v_total_secs, v_end_time_dec
    FROM games WHERE game_id = v_g1;

  ASSERT v_ver_after = v_ver_before + 1,
    format('add_time happy: state_version %s -> %s', v_ver_before, v_ver_after);
  ASSERT v_total_secs = 3600 + 60,
    format('add_time happy: total_decided_duration_seconds should be 3660, got %s', v_total_secs);

  -- ---- Happy: add another 120s (accumulation) ----------------------------
  SELECT state_version, total_decided_duration_seconds
    INTO v_ver_before, v_total_secs
    FROM games WHERE game_id = v_g1;

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'add_time', v_alice, '{"additional_seconds": 120}')
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_add_time(v_cmd_id);

  SELECT total_decided_duration_seconds INTO v_total_secs FROM games WHERE game_id = v_g1;
  ASSERT v_total_secs = 3660 + 120,
    format('add_time accumulate: expected 3780, got %s', v_total_secs);


  -- =========================================================================
  -- process_end_trading
  -- =========================================================================

  -- ---- UE001: command not found ------------------------------------------
  BEGIN
    PERFORM process_end_trading('00000000-0000-0000-0000-000000000000'::uuid);
    RAISE EXCEPTION 'FAIL: end_trading command not found should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: wrong command_type -----------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_end_trading(v_cmd_id);
    RAISE EXCEPTION 'FAIL: end_trading wrong type should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE002: wrong game_state (G3 is created) ---------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'end_trading', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_end_trading(v_cmd_id);
    RAISE EXCEPTION 'FAIL: end_trading on created game should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: non-admin caller (bob) on G1 -------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'end_trading', v_bob)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_end_trading(v_cmd_id);
    RAISE EXCEPTION 'FAIL: end_trading non-admin should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: outsider (carol) on G1 -------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'end_trading', v_carol)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_end_trading(v_cmd_id);
    RAISE EXCEPTION 'FAIL: end_trading outsider should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: system path on endless game (G2 is trading_started + endless)
  INSERT INTO commands (command_game_id, command_type)
    VALUES (v_g2, 'end_trading')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_end_trading(v_cmd_id);
    RAISE EXCEPTION 'FAIL: system end_trading on endless game should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: system path on timed game but deadline not yet passed -------
  -- G1 end_time_decided is ~now+3780s (still in future after add_time tests)
  INSERT INTO commands (command_game_id, command_type)
    VALUES (v_g1, 'end_trading')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_end_trading(v_cmd_id);
    RAISE EXCEPTION 'FAIL: system end_trading before deadline should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- Happy admin path: end G2 (endless, trading_started) ---------------
  -- Seed three orders on G2 covering all three flippable statuses, plus two
  -- terminal statuses that must NOT be touched.
  INSERT INTO orders (created_by_player_id, game_id, type, quantity_initial, quantity_current, price_per_stock, status)
    VALUES
      (v_alice, v_g2, 'limit_buy',  10, 10, 50.00, 'in_queue'),
      (v_bob,   v_g2, 'limit_sell',  5,  5, 60.00, 'being_processed'),
      (v_alice, v_g2, 'limit_buy',   3,  3, 45.00, 'order_resting'),
      (v_bob,   v_g2, 'limit_sell',  7,  0, 55.00, 'order_closed'),    -- terminal, must stay
      (v_alice, v_g2, 'limit_sell',  2,  0, 52.00, 'cancelled');        -- terminal, must stay

  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g2;

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g2, 'end_trading', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_end_trading(v_cmd_id);

  SELECT game_state, state_version, end_time_actual
    INTO v_state, v_ver_after, v_end_time_act
    FROM games WHERE game_id = v_g2;

  ASSERT v_state = 'trading_ended',
    format('end_trading admin: expected trading_ended, got %s', v_state);
  ASSERT v_ver_after = v_ver_before + 1,
    format('end_trading admin: state_version %s -> %s', v_ver_before, v_ver_after);
  ASSERT v_end_time_act IS NOT NULL,
    'end_trading admin: end_time_actual should be set';

  -- Verify three active orders flipped to game_ended
  SELECT count(*) INTO v_count
    FROM orders
    WHERE game_id = v_g2 AND status = 'game_ended';
  ASSERT v_count = 3,
    format('end_trading: expected 3 game_ended orders, got %s', v_count);

  -- Verify terminal statuses untouched
  SELECT count(*) INTO v_count
    FROM orders
    WHERE game_id = v_g2 AND status IN ('order_closed', 'cancelled');
  ASSERT v_count = 2,
    format('end_trading: expected 2 terminal orders untouched, got %s', v_count);

  -- state_version incremented exactly once (not once per order UPDATE)
  ASSERT v_ver_after = v_ver_before + 1,
    'end_trading: state_version must bump exactly once regardless of order count';

  -- ---- Happy system path: end G1 (timed, push deadline to past) ----------
  -- Put end_time_decided in the past to simulate timer expiry.
  UPDATE games
    SET end_time_decided = clock_timestamp() - interval '5 seconds'
    WHERE game_id = v_g1;

  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g1;

  -- system command: player_id IS NULL
  INSERT INTO commands (command_game_id, command_type)
    VALUES (v_g1, 'end_trading')
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_end_trading(v_cmd_id);

  SELECT game_state, state_version INTO v_state, v_ver_after
    FROM games WHERE game_id = v_g1;

  ASSERT v_state = 'trading_ended',
    format('end_trading system: expected trading_ended, got %s', v_state);
  ASSERT v_ver_after = v_ver_before + 1,
    format('end_trading system: state_version %s -> %s', v_ver_before, v_ver_after);

  -- ---- UE002: re-end G1 (already trading_ended) --------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'end_trading', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_end_trading(v_cmd_id);
    RAISE EXCEPTION 'FAIL: end_trading on already-ended game should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;


  -- =========================================================================
  -- process_set_envelope_price  (G1 and G2 are both trading_ended)
  -- =========================================================================

  -- ---- UE001: command not found ------------------------------------------
  BEGIN
    PERFORM process_set_envelope_price('00000000-0000-0000-0000-000000000000'::uuid);
    RAISE EXCEPTION 'FAIL: set_price command not found should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: wrong command_type -----------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'end_trading', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_set_envelope_price(v_cmd_id);
    RAISE EXCEPTION 'FAIL: set_price wrong type should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: null player_id ---------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', NULL, '{"envelope_price": "100"}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_set_envelope_price(v_cmd_id);
    RAISE EXCEPTION 'FAIL: set_price null player_id should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: missing envelope_price in payload --------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', v_alice, '{}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_set_envelope_price(v_cmd_id);
    RAISE EXCEPTION 'FAIL: set_price missing key should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: non-numeric envelope_price ---------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', v_alice, '{"envelope_price": "not-a-number"}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_set_envelope_price(v_cmd_id);
    RAISE EXCEPTION 'FAIL: set_price non-numeric should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: negative price (Q3) ----------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', v_alice, '{"envelope_price": "-1"}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_set_envelope_price(v_cmd_id);
    RAISE EXCEPTION 'FAIL: set_price negative should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE002: wrong game_state (G3 is created) ---------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g3, 'set_envelope_price', v_alice, '{"envelope_price": "100"}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_set_envelope_price(v_cmd_id);
    RAISE EXCEPTION 'FAIL: set_price on created game should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: non-admin caller -------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', v_bob, '{"envelope_price": "100"}')
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_set_envelope_price(v_cmd_id);
    RAISE EXCEPTION 'FAIL: set_price non-admin should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- Happy: zero price (worthless envelope is a valid outcome) ----------
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g1;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', v_alice, '{"envelope_price": "0"}')
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_set_envelope_price(v_cmd_id);
  SELECT state_version, envelope_price
    INTO v_ver_after, v_env_price
    FROM games WHERE game_id = v_g1;
  ASSERT v_ver_after = v_ver_before + 1,
    format('set_price zero: state_version %s -> %s', v_ver_before, v_ver_after);
  ASSERT v_env_price = 0,
    format('set_price zero: expected 0, got %s', v_env_price);

  -- ---- Happy: set price 100.50 on G1 -------------------------------------
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g1;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', v_alice, '{"envelope_price": "100.50"}')
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_set_envelope_price(v_cmd_id);
  SELECT state_version, envelope_price
    INTO v_ver_after, v_env_price
    FROM games WHERE game_id = v_g1;
  ASSERT v_ver_after = v_ver_before + 1,
    format('set_price first: state_version %s -> %s', v_ver_before, v_ver_after);
  ASSERT v_env_price = 100.50,
    format('set_price first: expected 100.50, got %s', v_env_price);

  -- ---- Happy: re-set price (edit) — multiple sets allowed in trading_ended
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g1;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_g1, 'set_envelope_price', v_alice, '{"envelope_price": "75.25"}')
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_set_envelope_price(v_cmd_id);
  SELECT state_version, envelope_price
    INTO v_ver_after, v_env_price
    FROM games WHERE game_id = v_g1;
  ASSERT v_env_price = 75.25,
    format('set_price edit: expected 75.25, got %s', v_env_price);
  ASSERT v_ver_after = v_ver_before + 1,
    format('set_price edit: state_version %s -> %s', v_ver_before, v_ver_after);


  -- =========================================================================
  -- process_finalise_game  (G1 is trading_ended with envelope_price=75.25)
  -- =========================================================================

  -- Set known delta values on alice and bob for deterministic PnL assertions.
  -- alice: sold 3 envelopes at high prices  → delta_cash=+500, delta_envelopes=-3
  --   PnL = 500 + 75.25 * (-3) = 500 - 225.75 = 274.25
  -- bob:   bought 3 envelopes               → delta_cash=-300, delta_envelopes=+3
  --   PnL = -300 + 75.25 * 3 = -300 + 225.75 = -74.25
  UPDATE games_players
    SET delta_cash = 500, delta_envelopes = -3
    WHERE map_game_id = v_g1 AND map_player_id = v_alice;
  UPDATE games_players
    SET delta_cash = -300, delta_envelopes = 3
    WHERE map_game_id = v_g1 AND map_player_id = v_bob;

  -- ---- UE001: command not found ------------------------------------------
  BEGIN
    PERFORM process_finalise_game('00000000-0000-0000-0000-000000000000'::uuid);
    RAISE EXCEPTION 'FAIL: finalise command not found should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: wrong command_type -----------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'end_trading', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_finalise_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: finalise wrong type should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: null player_id ---------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'finalise_game', NULL)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_finalise_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: finalise null player_id should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE002: wrong game_state (G3 is created) ---------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'finalise_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_finalise_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: finalise on created game should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: envelope_price IS NULL (G2 is trading_ended, no price set) --
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g2, 'finalise_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_finalise_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: finalise without price should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: non-admin caller -------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'finalise_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_finalise_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: finalise non-admin should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- Happy: finalise G1 ------------------------------------------------
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g1;

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'finalise_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_finalise_game(v_cmd_id);

  SELECT game_state, state_version INTO v_state, v_ver_after
    FROM games WHERE game_id = v_g1;

  ASSERT v_state = 'game_finalised',
    format('finalise: expected game_finalised, got %s', v_state);
  ASSERT v_ver_after = v_ver_before + 1,
    format('finalise: state_version %s -> %s', v_ver_before, v_ver_after);

  -- Assert PnL for alice: round(500 + 75.25 * (-3), 5) = 274.25000
  SELECT pnl INTO v_pnl_alice
    FROM games_players
    WHERE map_game_id = v_g1 AND map_player_id = v_alice;
  ASSERT v_pnl_alice = 274.25,
    format('finalise pnl alice: expected 274.25, got %s', v_pnl_alice);

  -- Assert PnL for bob: round(-300 + 75.25 * 3, 5) = -74.25000
  SELECT pnl INTO v_pnl_bob
    FROM games_players
    WHERE map_game_id = v_g1 AND map_player_id = v_bob;
  ASSERT v_pnl_bob = -74.25,
    format('finalise pnl bob: expected -74.25, got %s', v_pnl_bob);

  -- Assert lobby_status = 'finished' for both players
  SELECT lobby_status::text INTO v_ls_alice
    FROM games_players WHERE map_game_id = v_g1 AND map_player_id = v_alice;
  ASSERT v_ls_alice = 'finished',
    format('finalise lobby_status alice: expected finished, got %s', v_ls_alice);

  SELECT lobby_status::text INTO v_ls_bob
    FROM games_players WHERE map_game_id = v_g1 AND map_player_id = v_bob;
  ASSERT v_ls_bob = 'finished',
    format('finalise lobby_status bob: expected finished, got %s', v_ls_bob);

  -- ---- PnL 5-dp precision test -------------------------------------------
  -- price = 1.123456789, delta_cash = 0, delta_envelopes = 1
  -- round(0 + 1.123456789 * 1, 5) = round(1.123456789, 5) = 1.12346
  -- Use G2 (trading_ended, no price yet). Set it up locally.
  UPDATE games SET envelope_price = 1.123456789 WHERE game_id = v_g2;
  UPDATE games_players
    SET delta_cash = 0, delta_envelopes = 1
    WHERE map_game_id = v_g2 AND map_player_id = v_alice;
  UPDATE games_players
    SET delta_cash = 0, delta_envelopes = 0
    WHERE map_game_id = v_g2 AND map_player_id = v_bob;

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g2, 'finalise_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_finalise_game(v_cmd_id);

  SELECT pnl INTO v_pnl_alice
    FROM games_players WHERE map_game_id = v_g2 AND map_player_id = v_alice;
  ASSERT v_pnl_alice = 1.12346,
    format('finalise 5dp: expected 1.12346, got %s', v_pnl_alice);

  -- ---- UE002: double-finalise G1 (already game_finalised) ----------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'finalise_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_finalise_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: double-finalise should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;


  -- =========================================================================
  -- process_discard_game
  -- =========================================================================

  -- ---- UE001: command not found ------------------------------------------
  BEGIN
    PERFORM process_discard_game('00000000-0000-0000-0000-000000000000'::uuid);
    RAISE EXCEPTION 'FAIL: discard command not found should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: wrong command_type -----------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'end_trading', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_discard_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: discard wrong type should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE001: null player_id ---------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'discard_game', NULL)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_discard_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: discard null player_id should raise UE001';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- ---- UE002: wrong game_state = trading_started (G4) -------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g4, 'discard_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_discard_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: discard from trading_started should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: wrong game_state = game_finalised (G1) --------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g1, 'discard_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_discard_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: discard from game_finalised should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- UE002: non-admin caller -------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'discard_game', v_carol)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_discard_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: discard outsider should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- ---- Happy: discard G3 from created ------------------------------------
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g3;

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'discard_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_discard_game(v_cmd_id);

  SELECT game_state, state_version INTO v_state, v_ver_after
    FROM games WHERE game_id = v_g3;

  ASSERT v_state = 'discarded',
    format('discard from created: expected discarded, got %s', v_state);
  ASSERT v_ver_after = v_ver_before + 1,
    format('discard from created: state_version %s -> %s', v_ver_before, v_ver_after);

  -- Verify alice's lobby_status flipped (Q5)
  SELECT lobby_status::text INTO v_ls_alice
    FROM games_players WHERE map_game_id = v_g3 AND map_player_id = v_alice;
  ASSERT v_ls_alice = 'finished',
    format('discard from created: alice lobby_status expected finished, got %s', v_ls_alice);

  -- ---- Happy: discard G2 from trading_ended (game_finalised G2 earlier) --
  -- G2 is already game_finalised from the 5-dp test. We need a trading_ended
  -- game that has NOT been finalised. Use G4: advance it to trading_ended via
  -- direct UPDATE (it's currently trading_started, endless).
  UPDATE games
    SET game_state = 'trading_ended', end_time_actual = clock_timestamp()
    WHERE game_id = v_g4;

  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_g4;

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g4, 'discard_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_discard_game(v_cmd_id);

  SELECT game_state, state_version INTO v_state, v_ver_after
    FROM games WHERE game_id = v_g4;

  ASSERT v_state = 'discarded',
    format('discard from trading_ended: expected discarded, got %s', v_state);
  ASSERT v_ver_after = v_ver_before + 1,
    format('discard from trading_ended: state_version %s -> %s', v_ver_before, v_ver_after);

  -- lobby_status for alice on G4 should be 'finished'
  SELECT lobby_status::text INTO v_ls_alice
    FROM games_players WHERE map_game_id = v_g4 AND map_player_id = v_alice;
  ASSERT v_ls_alice = 'finished',
    format('discard from trading_ended: alice lobby_status expected finished, got %s', v_ls_alice);

  -- ---- UE002: double-discard G3 (already discarded) ----------------------
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_g3, 'discard_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_discard_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: double-discard should raise UE002';
  EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  RAISE NOTICE 'A5 lifecycle tests: ALL PASSED';

END;
$a5_test$;

ROLLBACK;
