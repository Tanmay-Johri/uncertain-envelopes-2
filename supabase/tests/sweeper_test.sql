-- ============================================================================
-- Test: sweeper_test
-- Stream A / A9-TEST: sweeper_rescue_stuck_claimed, sweeper_auto_end_timed_games,
--   sweeper_kick_idle_processors, sweeper_run (DB state only; pg_net HTTP is
--   no-op when vault secrets are absent — still safe to run).
--
-- Strategy: BEGIN … ROLLBACK, seed minimal games/commands, call sweeper SQL
--   functions, ASSERT row states. Does not assert net._http_response.
-- ============================================================================

BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('a9000000-0000-0000-0000-000000000001', 'alice@sweep.test'),
  ('a9000000-0000-0000-0000-000000000002', 'bob@sweep.test');

INSERT INTO players (player_id, username, email) VALUES
  ('a9000000-0000-0000-0000-000000000001', 'alice9', 'alice@sweep.test'),
  ('a9000000-0000-0000-0000-000000000002', 'bob9',   'bob@sweep.test');

DO $sweep_test$
DECLARE
  v_alice       uuid := 'a9000000-0000-0000-0000-000000000001';
  v_bob         uuid := 'a9000000-0000-0000-0000-000000000002';
  v_cmd         uuid;
  v_create      uuid;
  v_game        uuid;
  v_game2       uuid;
  v_row         commands%ROWTYPE;
  v_rescue_n    bigint;
  v_rescue_http bigint;
  v_auto        bigint;
  v_kick        bigint;
  v_cnt         integer;
  v_j           jsonb;
BEGIN

  -- -------------------------------------------------------------------------
  -- Timed game G1: started, deadline moved to the past (for auto-end)
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','Sweep Timed','game_security','public','is_ranked','casual',
    'game_max_players',5,'end_condition','timed','total_decided_duration_seconds',3600
  )) RETURNING command_id INTO v_create;
  v_game := process_create_game(v_create);

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game, 'join_game', v_bob)
    RETURNING command_id INTO v_cmd;
  PERFORM process_join_game(v_cmd);

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd;
  PERFORM process_start_game(v_cmd);

  UPDATE games
  SET end_time_decided = clock_timestamp() - interval '2 minutes'
  WHERE game_id = v_game;

  -- -------------------------------------------------------------------------
  -- Endless game G2: started (no auto-end)
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_type, player_id, payload)
  VALUES ('create_game', v_alice, jsonb_build_object(
    'game_name','Sweep Endless','game_security','public','is_ranked','casual',
    'game_max_players',5,'end_condition','endless'
  )) RETURNING command_id INTO v_create;
  v_game2 := process_create_game(v_create);

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game2, 'join_game', v_bob)
    RETURNING command_id INTO v_cmd;
  PERFORM process_join_game(v_cmd);

  INSERT INTO commands (command_game_id, command_type, player_id)
    VALUES (v_game2, 'start_game', v_alice)
    RETURNING command_id INTO v_cmd;
  PERFORM process_start_game(v_cmd);

  -- -------------------------------------------------------------------------
  -- Rescue: stale claimed → failed (attempt_count preserved)
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, command_status, attempt_count)
  VALUES (v_game, 'add_time', v_alice, 'pending', 2)
  RETURNING command_id INTO v_cmd;

  UPDATE commands
  SET command_status = 'claimed',
      claim_token    = gen_random_uuid(),
      claimed_at     = clock_timestamp() - interval '90 seconds',
      attempt_count  = 2
  WHERE command_id = v_cmd;

  SELECT r.rescued_commands, r.http_kicks
  INTO v_rescue_n, v_rescue_http
  FROM sweeper_rescue_stuck_claimed() AS r;

  ASSERT v_rescue_n = 1, format('rescue: expected 1 rescued row, got %s', v_rescue_n);

  SELECT * INTO v_row FROM commands WHERE command_id = v_cmd;
  ASSERT v_row.command_status = 'failed', format('rescue: status %s', v_row.command_status);
  ASSERT v_row.attempt_count = 2, format('rescue: attempt_count should stay 2, got %s', v_row.attempt_count);
  ASSERT v_row.claim_token IS NULL AND v_row.claimed_at IS NULL, 'rescue: claim cleared';

  -- -------------------------------------------------------------------------
  -- Rescue: fresh claimed (< 30s) is NOT touched
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, command_status, attempt_count)
  VALUES (v_game, 'add_time', v_alice, 'pending', 0)
  RETURNING command_id INTO v_cmd;

  UPDATE commands
  SET command_status = 'claimed',
      claim_token    = gen_random_uuid(),
      claimed_at     = clock_timestamp() - interval '5 seconds',
      attempt_count  = 1
  WHERE command_id = v_cmd;

  SELECT r.rescued_commands INTO v_rescue_n FROM sweeper_rescue_stuck_claimed() AS r;

  ASSERT v_rescue_n = 0, format('rescue fresh: expected 0 rescued, got %s', v_rescue_n);

  SELECT * INTO v_row FROM commands WHERE command_id = v_cmd;
  ASSERT v_row.command_status = 'claimed', 'rescue fresh: must stay claimed';

  -- -------------------------------------------------------------------------
  -- Auto-end: timed past deadline inserts system end_trading
  -- -------------------------------------------------------------------------
  v_auto := sweeper_auto_end_timed_games();
  ASSERT v_auto >= 1, format('auto_end: expected >=1 insert, got %s', v_auto);

  SELECT COUNT(*) INTO v_cnt
  FROM commands
  WHERE command_game_id = v_game
    AND command_type = 'end_trading'
    AND player_id IS NULL
    AND command_status = 'pending';

  ASSERT v_cnt = 1, format('auto_end: expected 1 pending system end_trading, got %s', v_cnt);

  -- Duplicate guard: second call inserts nothing for same game
  v_auto := sweeper_auto_end_timed_games();
  ASSERT v_auto = 0, format('auto_end dup: expected 0, got %s', v_auto);

  SELECT COUNT(*) INTO v_cnt
  FROM commands
  WHERE command_game_id = v_game AND command_type = 'end_trading';
  ASSERT v_cnt = 1, 'auto_end dup: still exactly one end_trading row';

  -- Endless game must not get system end_trading from sweeper
  SELECT COUNT(*) INTO v_cnt
  FROM commands
  WHERE command_game_id = v_game2 AND command_type = 'end_trading';
  ASSERT v_cnt = 0, format('endless: no end_trading expected, got %s', v_cnt);

  -- -------------------------------------------------------------------------
  -- Kick idle: partition with pending + recent claimed → excluded (0 targets)
  -- -------------------------------------------------------------------------
  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (
    v_game2,
    'add_time',
    v_alice,
    jsonb_build_object('additional_seconds', 120)
  );

  INSERT INTO commands (command_game_id, command_type, player_id, payload)
  VALUES (
    v_game2,
    'add_time',
    v_alice,
    jsonb_build_object('additional_seconds', 60)
  )
  RETURNING command_id INTO v_cmd;

  UPDATE commands
  SET command_status = 'claimed',
      claim_token    = gen_random_uuid(),
      claimed_at     = clock_timestamp() - interval '3 seconds'
  WHERE command_id = v_cmd;

  SELECT COUNT(*) INTO v_cnt
  FROM (
    SELECT DISTINCT ON (COALESCE(c.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid))
      c.command_id
    FROM commands c
    WHERE (
            c.command_status = 'pending'
         OR (c.command_status = 'failed' AND c.attempt_count < 3)
          )
      AND NOT command_processor_has_recent_claim(c.command_game_id)
      AND c.command_game_id = v_game2
    ORDER BY COALESCE(c.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid), c.command_created_at ASC
  ) sub;

  ASSERT v_cnt = 0, 'kick query: recent claim must hide idle pending for same game';

  -- Clear claimed row so the other pending add_time becomes kick-eligible
  UPDATE commands
  SET command_status = 'failed',
      claim_token    = NULL,
      claimed_at     = NULL
  WHERE command_id = v_cmd;

  SELECT COUNT(*) INTO v_cnt
  FROM (
    SELECT DISTINCT ON (COALESCE(c.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid))
      c.command_id
    FROM commands c
    WHERE (
            c.command_status = 'pending'
         OR (c.command_status = 'failed' AND c.attempt_count < 3)
          )
      AND NOT command_processor_has_recent_claim(c.command_game_id)
      AND c.command_game_id = v_game2
    ORDER BY COALESCE(c.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid), c.command_created_at ASC
  ) sub2;

  ASSERT v_cnt >= 1, 'kick query: without recent claim, at least one idle partition row';

  v_kick := sweeper_kick_idle_processors();
  ASSERT v_kick >= 0, 'kick: returns non-negative http count';

  -- -------------------------------------------------------------------------
  -- sweeper_run: returns expected JSON shape
  -- -------------------------------------------------------------------------
  v_j := sweeper_run();
  ASSERT v_j ? 'rescued_commands', 'sweeper_run: missing rescued_commands';
  ASSERT v_j ? 'auto_end_inserts', 'sweeper_run: missing auto_end_inserts';
  ASSERT v_j ? 'idle_http_kicks', 'sweeper_run: missing idle_http_kicks';

END;
$sweep_test$;

ROLLBACK;
