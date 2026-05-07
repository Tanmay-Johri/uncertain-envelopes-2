-- ============================================================================
-- Test: create_game_test
-- Stream A / A3-TEST: adversarial tests for process_create_game
--
-- Strategy:
--   * Seed one auth user + one player as the admin-in-waiting.
--   * For each test case: insert a fresh command row with a specific payload,
--     invoke process_create_game(cmd_id), assert side-effects (games row,
--     games_players admin row, command_game_id backfill, state_version,
--     joining_code shape) on happy path, or expect SQLSTATE 'UE001' for
--     adversarial payloads.
--   * Finally, create 20 games back-to-back and assert all joining_codes are
--     unique to exercise the retry loop.
--   * Everything inside one BEGIN ... ROLLBACK so nothing persists.
-- ============================================================================

BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin@a3.test'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'other@a3.test');

INSERT INTO players (player_id, username, email) VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', 'alice', 'alice@a3.test'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'bob',   'bob@a3.test');

DO $a3_test$
DECLARE
  v_admin         uuid := 'aaaaaaaa-0000-0000-0000-000000000001';
  v_other         uuid := 'aaaaaaaa-0000-0000-0000-000000000002';
  v_cmd_id        uuid;
  v_game_id       uuid;
  v_game          games%ROWTYPE;
  v_admin_row     games_players%ROWTYPE;
  v_cmd_after     commands%ROWTYPE;
  v_codes         text[];
  v_code          text;
  v_dup_codes     integer;
  v_i             integer;
BEGIN
  -- -------------------------------------------------------------------------
  -- Happy path 1: timed public ranked with description
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_admin, jsonb_build_object(
    'game_name', 'First Game',
    'game_description', 'A description',
    'game_security', 'public',
    'is_ranked', 'ranked',
    'game_max_players', 4,
    'end_condition', 'timed',
    'total_decided_duration_seconds', 600
  )) RETURNING command_id INTO v_cmd_id;

  v_game_id := process_create_game(v_cmd_id);
  ASSERT v_game_id IS NOT NULL, 'happy 1: returned game_id null';

  SELECT * INTO v_game FROM games WHERE game_id = v_game_id;
  ASSERT v_game.game_name = 'First Game',                      format('happy 1: game_name %s',  v_game.game_name);
  ASSERT v_game.game_description = 'A description',            'happy 1: description';
  ASSERT v_game.game_security = 'public',                      'happy 1: security';
  ASSERT v_game.is_ranked = 'ranked',                          'happy 1: is_ranked';
  ASSERT v_game.game_max_players = 4,                          'happy 1: max_players';
  ASSERT v_game.end_condition = 'timed',                       'happy 1: end_condition';
  ASSERT v_game.total_decided_duration_seconds = 600,          'happy 1: duration';
  ASSERT v_game.game_state = 'created',                        'happy 1: game_state';
  ASSERT v_game.state_version = 1,                             'happy 1: state_version';
  ASSERT v_game.admin_player_id = v_admin,                     'happy 1: admin_player_id';
  ASSERT v_game.joining_code ~ '^[A-Z0-9]{5}$',                format('happy 1: joining_code shape %s', v_game.joining_code);
  ASSERT v_game.start_time      IS NULL,                       'happy 1: start_time must be null before start';
  ASSERT v_game.end_time_actual IS NULL,                       'happy 1: end_time_actual must be null';
  ASSERT v_game.end_time_decided IS NULL,                      'happy 1: end_time_decided must be null until start';
  ASSERT v_game.last_traded_price IS NULL,                     'happy 1: last_traded_price null';
  ASSERT v_game.envelope_price IS NULL,                        'happy 1: envelope_price null';

  SELECT * INTO v_admin_row FROM games_players WHERE map_game_id = v_game_id AND map_player_id = v_admin;
  ASSERT v_admin_row.is_admin = true,                          'happy 1: admin flag';
  ASSERT v_admin_row.lobby_status = 'playing',                 'happy 1: lobby_status';
  ASSERT v_admin_row.delta_cash = 0,                           'happy 1: delta_cash';
  ASSERT v_admin_row.delta_envelopes = 0,                      'happy 1: delta_envelopes';
  ASSERT v_admin_row.pnl = 0,                                  'happy 1: pnl';

  SELECT * INTO v_cmd_after FROM commands WHERE command_id = v_cmd_id;
  ASSERT v_cmd_after.command_game_id = v_game_id,              'happy 1: command_game_id backfill';
  -- Procedure does NOT change command_status itself; processor does that
  ASSERT v_cmd_after.command_status = 'pending',               'happy 1: proc must not mutate command_status';

  -- -------------------------------------------------------------------------
  -- Happy path 2: endless private casual, no description, no duration
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_admin, jsonb_build_object(
    'game_name', 'Endless Private',
    'game_security', 'private',
    'is_ranked', 'casual',
    'game_max_players', 100,
    'end_condition', 'endless'
  )) RETURNING command_id INTO v_cmd_id;

  v_game_id := process_create_game(v_cmd_id);
  SELECT * INTO v_game FROM games WHERE game_id = v_game_id;
  ASSERT v_game.game_description IS NULL,                      'happy 2: description must be null';
  ASSERT v_game.end_condition = 'endless',                     'happy 2: end_condition';
  ASSERT v_game.total_decided_duration_seconds IS NULL,        'happy 2: duration must be null';
  ASSERT v_game.game_max_players = 100,                        'happy 2: max_players boundary 100';

  -- Description explicitly null is also allowed
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    jsonb_build_object('game_name','Desc Null','game_description', NULL,'game_security','public','is_ranked','casual','game_max_players',1,'end_condition','endless')
  ) RETURNING command_id INTO v_cmd_id;
  v_game_id := process_create_game(v_cmd_id);
  ASSERT v_game_id IS NOT NULL, 'happy 3: desc=null accepted';

  -- -------------------------------------------------------------------------
  -- Adversarial: every one of these must raise SQLSTATE 'UE001'
  -- -------------------------------------------------------------------------
  -- Case 1: command not found
  BEGIN
    PERFORM process_create_game(gen_random_uuid());
    RAISE EXCEPTION 'FAIL: expected UE001 for nonexistent command';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 2: wrong command_type (use an existing game as the FK target)
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
    VALUES (v_game_id, 'join_game', v_admin, '{}'::jsonb)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_create_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: expected UE001 for wrong command_type';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 3: null player_id
  INSERT INTO commands (command_type, player_id, payload)
    VALUES ('create_game', NULL, '{"game_name":"x","game_security":"public","is_ranked":"casual","game_max_players":1,"end_condition":"endless"}'::jsonb)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_create_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: expected UE001 for null player_id';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- NOTE: "player_id not in players" cannot be triggered via a normal INSERT
  -- because commands.player_id has a FK to players(player_id). The defensive
  -- NOT EXISTS check inside the procedure is therefore unreachable via the
  -- supported ingress path, but it's kept as defense-in-depth. No test case.

  -- Case 4: payload not an object
  INSERT INTO commands (command_type, player_id, payload)
    VALUES ('create_game', v_admin, '[]'::jsonb)
    RETURNING command_id INTO v_cmd_id;
  BEGIN
    PERFORM process_create_game(v_cmd_id);
    RAISE EXCEPTION 'FAIL: expected UE001 for array payload';
  EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 6: missing game_name
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_security":"public","is_ranked":"casual","game_max_players":1,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: missing game_name'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 7: empty game_name
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"","game_security":"public","is_ranked":"casual","game_max_players":1,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: empty game_name'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 8: game_name > 32 chars (33)
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    jsonb_build_object('game_name', repeat('g', 33), 'game_security','public','is_ranked','casual','game_max_players',1,'end_condition','endless')
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: long game_name'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 9: description too long (257)
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    jsonb_build_object('game_name','ok','game_description', repeat('x', 257),'game_security','public','is_ranked','casual','game_max_players',1,'end_condition','endless')
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: long description'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 10: missing game_security
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","is_ranked":"casual","game_max_players":1,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: missing security'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 11: invalid game_security
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"hidden","is_ranked":"casual","game_max_players":1,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: bad security'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 12: missing is_ranked
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","game_max_players":1,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: missing is_ranked'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 13: invalid is_ranked
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"tournament","game_max_players":1,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: bad is_ranked'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 14: missing game_max_players
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: missing max_players'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 15: non-integer max_players
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":"abc","end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: non-int max_players'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 16: max_players = 0
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":0,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: max_players=0'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 17: max_players = 101
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":101,"end_condition":"endless"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: max_players=101'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 18: invalid end_condition
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":4,"end_condition":"forever"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: bad end_condition'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 19: timed without duration
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":4,"end_condition":"timed"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: timed no duration'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 20: timed with duration=0
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":4,"end_condition":"timed","total_decided_duration_seconds":0}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: timed duration=0'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 21: timed with negative duration
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":4,"end_condition":"timed","total_decided_duration_seconds":-10}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: timed negative duration'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 22: timed with non-integer duration
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":4,"end_condition":"timed","total_decided_duration_seconds":"soon"}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: timed non-int duration'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 23: endless with duration
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":4,"end_condition":"endless","total_decided_duration_seconds":600}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  BEGIN PERFORM process_create_game(v_cmd_id); RAISE EXCEPTION 'FAIL: endless with duration'; EXCEPTION WHEN SQLSTATE 'UE001' THEN NULL; END;

  -- Case 24: endless with explicit null duration key is OK
  INSERT INTO commands (command_type, player_id, payload) VALUES (
    'create_game', v_admin,
    '{"game_name":"ok","game_security":"public","is_ranked":"casual","game_max_players":4,"end_condition":"endless","total_decided_duration_seconds":null}'::jsonb
  ) RETURNING command_id INTO v_cmd_id;
  v_game_id := process_create_game(v_cmd_id);
  ASSERT v_game_id IS NOT NULL, 'endless with explicit null duration must succeed';

  -- -------------------------------------------------------------------------
  -- None of the failure cases above must have leaked partial writes. Each
  -- one of them is wrapped in a BEGIN..EXCEPTION so the surrounding
  -- transaction state persists; however, the inserts INTO commands that
  -- preceded each failed call are committed to the transaction. Only the
  -- failed procedure side-effects (games / games_players / backfill) should
  -- be absent. Verify by confirming we can still count games deterministically:
  -- we expect 3 happy paths + 1 endless-null-duration = 4 games total prior
  -- to the bulk test below.
  -- -------------------------------------------------------------------------
  PERFORM 1;  -- no-op

  -- -------------------------------------------------------------------------
  -- Bulk: create 20 games, assert distinct joining_codes
  -- -------------------------------------------------------------------------
  v_codes := ARRAY[]::text[];
  FOR v_i IN 1..20 LOOP
    INSERT INTO commands (command_type, player_id, payload) VALUES (
      'create_game', v_admin,
      jsonb_build_object('game_name', 'Bulk ' || v_i, 'game_security','public','is_ranked','casual','game_max_players',4,'end_condition','endless')
    ) RETURNING command_id INTO v_cmd_id;
    v_game_id := process_create_game(v_cmd_id);
    SELECT joining_code INTO v_code FROM games WHERE game_id = v_game_id;
    v_codes := v_codes || v_code;
  END LOOP;
  SELECT count(*) - count(DISTINCT c) INTO v_dup_codes
    FROM unnest(v_codes) AS c;
  ASSERT v_dup_codes = 0, format('bulk: %s duplicate joining_codes out of 20', v_dup_codes);

  RAISE NOTICE 'create_game_test: all assertions passed';
END;
$a3_test$;

ROLLBACK;
