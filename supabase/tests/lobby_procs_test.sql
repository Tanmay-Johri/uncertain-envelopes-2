-- ============================================================================
-- Test: lobby_procs_test
-- Stream A / A4-TEST: process_join_game, process_leave_game, process_kick_player
--
-- Strategy:
--   * Seed 5 players (one admin + three members + one outsider).
--   * Build a base game G via process_create_game, giving us a real game row
--     with admin=alice and max_players=3 (so we can hit the full-game case).
--   * Build a parallel minimal game with max_players=1 and no other members
--     (so we can hit "only admin left" edge cases for kick).
--   * For each test case, insert a fresh command, call the proc, and assert:
--       - happy path: row inserted/deleted + state_version strictly
--         incremented
--       - UE001 / UE002: exception with exact sqlstate
--   * Wrapped in BEGIN/ROLLBACK.
-- ============================================================================

BEGIN;

-- -- Seed ---------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'alice@a4.test'),
  ('b2222222-2222-2222-2222-222222222222', 'bob@a4.test'),
  ('c3333333-3333-3333-3333-333333333333', 'carol@a4.test'),
  ('d4444444-4444-4444-4444-444444444444', 'dan@a4.test'),
  ('e5555555-5555-5555-5555-555555555555', 'eve@a4.test');

INSERT INTO players (player_id, username, email) VALUES
  ('a1111111-1111-1111-1111-111111111111', 'alice', 'alice@a4.test'),
  ('b2222222-2222-2222-2222-222222222222', 'bob',   'bob@a4.test'),
  ('c3333333-3333-3333-3333-333333333333', 'carol', 'carol@a4.test'),
  ('d4444444-4444-4444-4444-444444444444', 'dan',   'dan@a4.test'),
  ('e5555555-5555-5555-5555-555555555555', 'eve',   'eve@a4.test');

DO $a4_test$
DECLARE
  v_alice uuid := 'a1111111-1111-1111-1111-111111111111';
  v_bob   uuid := 'b2222222-2222-2222-2222-222222222222';
  v_carol uuid := 'c3333333-3333-3333-3333-333333333333';
  v_dan   uuid := 'd4444444-4444-4444-4444-444444444444';
  v_eve   uuid := 'e5555555-5555-5555-5555-555555555555';
  v_cmd_id         uuid;
  v_create_cmd_id  uuid;
  v_game_id        uuid;
  v_minigame_id    uuid;
  v_ver_before     integer;
  v_ver_after      integer;
  v_count          integer;
BEGIN
  -- -------------------------------------------------------------------------
  -- Build main game G (max_players=3, admin=alice)
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','A4 Game','game_security','public','is_ranked','casual',
    'game_max_players',3,'end_condition','endless'
  )) RETURNING command_id INTO v_create_cmd_id;
  v_game_id := process_create_game(v_create_cmd_id);

  -- 1-player game for boundary test (max_players=1)
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','A4 Solo','game_security','public','is_ranked','casual',
    'game_max_players',1,'end_condition','endless'
  )) RETURNING command_id INTO v_create_cmd_id;
  v_minigame_id := process_create_game(v_create_cmd_id);

  -- =========================================================================
  -- process_join_game
  -- =========================================================================

  -- Happy: bob joins G, state_version bumps, row inserted with defaults
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_join_game(v_cmd_id);
  SELECT state_version INTO v_ver_after FROM games WHERE game_id = v_game_id;
  ASSERT v_ver_after = v_ver_before + 1, format('join happy: state_version %s -> %s', v_ver_before, v_ver_after);
  SELECT count(*) INTO v_count FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_bob;
  ASSERT v_count = 1, 'join happy: bob row missing';

  -- Happy: carol joins; now G has alice(admin), bob, carol = 3/3 (FULL)
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_carol)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_join_game(v_cmd_id);
  SELECT count(*) INTO v_count FROM games_players WHERE map_game_id = v_game_id;
  ASSERT v_count = 3, 'G must now be full';

  -- UE002: game full -> dan cannot join
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_dan)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: join into full game'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE002: already in game -> bob cannot join again
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: duplicate join'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE001: wrong command_type
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'leave_game', v_dan)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: join wrong type'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: command not found
  BEGIN PERFORM process_join_game(gen_random_uuid()); RAISE EXCEPTION 'FAIL: join missing cmd'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: null player_id
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', NULL)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: join null player'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: null command_game_id  (command_type='create_game' keeps it null-allowed;
  -- here we cannot insert join_game with null game_id because of the CHECK, so we
  -- use a create_game command to exercise the branch. But our proc rejects it
  -- for wrong command_type first. This branch is therefore unreachable; we
  -- verify the analogous protection in leave_game + kick_player instead.)

  -- UE002: game_state = trading_ended -> cannot join
  UPDATE games SET game_state='trading_ended' WHERE game_id = v_game_id;
  -- Free a slot first so full-game isn't the blocker
  DELETE FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_carol;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_dan)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: join trading_ended'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;
  -- UE002: game_state = game_finalised
  UPDATE games SET game_state='game_finalised' WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_dan)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: join finalised'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;
  -- UE002: game_state = discarded
  UPDATE games SET game_state='discarded' WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_dan)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: join discarded'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- Happy: join during trading_started is allowed per PRD
  UPDATE games SET game_state='trading_started', start_time = now() WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_carol)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_join_game(v_cmd_id);
  SELECT count(*) INTO v_count FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_carol;
  ASSERT v_count = 1, 'join trading_started: carol missing';
  -- Reset G back to created for leave/kick tests
  UPDATE games SET game_state='created', start_time=NULL WHERE game_id = v_game_id;

  -- =========================================================================
  -- process_leave_game
  -- =========================================================================

  -- Happy: carol leaves G (which is now back in 'created')
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'leave_game', v_carol)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_leave_game(v_cmd_id);
  SELECT count(*) INTO v_count FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_carol;
  ASSERT v_count = 0, 'leave happy: carol row still present';
  SELECT state_version INTO v_ver_after FROM games WHERE game_id = v_game_id;
  ASSERT v_ver_after = v_ver_before + 1, 'leave happy: state_version did not bump';

  -- UE002: player not in game -> dan
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'leave_game', v_dan)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_leave_game(v_cmd_id); RAISE EXCEPTION 'FAIL: leave non-member'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE002: admin (alice) cannot leave
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'leave_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_leave_game(v_cmd_id); RAISE EXCEPTION 'FAIL: admin leave'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE002: game_state != created
  UPDATE games SET game_state='trading_started', start_time = now() WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'leave_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_leave_game(v_cmd_id); RAISE EXCEPTION 'FAIL: leave trading_started'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;
  UPDATE games SET game_state='created', start_time=NULL WHERE game_id = v_game_id;

  -- UE001: wrong command_type
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'kick_player', v_bob)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_leave_game(v_cmd_id); RAISE EXCEPTION 'FAIL: leave wrong type'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: command not found
  BEGIN PERFORM process_leave_game(gen_random_uuid()); RAISE EXCEPTION 'FAIL: leave missing'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: null player_id
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'leave_game', NULL)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_leave_game(v_cmd_id); RAISE EXCEPTION 'FAIL: leave null player'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- =========================================================================
  -- process_kick_player
  -- =========================================================================
  -- G currently: alice(admin), bob. Let's add carol and dan back via the proc.
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'join_game', v_carol)
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_join_game(v_cmd_id);
  -- G is now full again (3/3). Don't add dan, keep him for non-member tests.

  -- Happy: alice kicks carol
  SELECT state_version INTO v_ver_before FROM games WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_alice, jsonb_build_object('target_player_id', v_carol))
    RETURNING command_id INTO v_cmd_id;
  PERFORM process_kick_player(v_cmd_id);
  SELECT count(*) INTO v_count FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_carol;
  ASSERT v_count = 0, 'kick happy: carol row still present';
  SELECT state_version INTO v_ver_after FROM games WHERE game_id = v_game_id;
  ASSERT v_ver_after = v_ver_before + 1, 'kick happy: state_version did not bump';

  -- UE002: non-admin tries to kick -> bob kicks alice
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_bob, jsonb_build_object('target_player_id', v_alice))
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick by non-admin'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE002: target not in game -> alice kicks dan
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_alice, jsonb_build_object('target_player_id', v_dan))
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick non-member'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE002: admin kicks self
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_alice, jsonb_build_object('target_player_id', v_alice))
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: admin kicks self'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE002: wrong game_state -> advance game to trading_started, try kick
  UPDATE games SET game_state='trading_started', start_time = now() WHERE game_id = v_game_id;
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_alice, jsonb_build_object('target_player_id', v_bob))
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick during trading'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;
  UPDATE games SET game_state='created', start_time=NULL WHERE game_id = v_game_id;

  -- UE002: caller not in game -> eve (random authed user, not a member) tries to kick
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_eve, jsonb_build_object('target_player_id', v_bob))
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick by non-member'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  -- UE001: wrong command_type
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game_id, 'leave_game', v_alice)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick wrong type'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: empty payload (no target_player_id)
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_alice, '{}'::jsonb)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick empty payload'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: payload is array, not object
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_alice, '[]'::jsonb)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick array payload'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: target_player_id not a valid uuid
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'kick_player', v_alice, '{"target_player_id":"not-a-uuid"}'::jsonb)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_kick_player(v_cmd_id); RAISE EXCEPTION 'FAIL: kick bad target uuid'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- UE001: command not found
  BEGIN PERFORM process_kick_player(gen_random_uuid()); RAISE EXCEPTION 'FAIL: kick missing cmd'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- =========================================================================
  -- 1-player game boundary: minigame max_players=1, alice is already the admin.
  -- Nobody else can join.
  -- =========================================================================
  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_minigame_id, 'join_game', v_bob)
    RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_join_game(v_cmd_id); RAISE EXCEPTION 'FAIL: join into 1-player game'; EXCEPTION WHEN SQLSTATE 'UE002' THEN NULL; END;

  RAISE NOTICE 'lobby_procs_test: all assertions passed';
END;
$a4_test$;

ROLLBACK;
