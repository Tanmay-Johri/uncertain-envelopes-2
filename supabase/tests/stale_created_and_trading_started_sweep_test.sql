-- ============================================================================
-- Test: stale_created_and_trading_started_sweep_test
-- Verifies:
--   * sweeper_stale_created_games discards created games 24+ hours old
--   * sweeper_stale_trading_started_games ends trading_started games idle 36+ h
-- ============================================================================

BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('ee555555-eeee-eeee-eeee-eeeeeeeeeeee', 'stale17@test.co');

INSERT INTO players (player_id, username, email) VALUES
  ('ee555555-eeee-eeee-eeee-eeeeeeeeeeee', 'stale17admin', 'stale17@test.co');

DO $sweep17$
DECLARE
  v_admin uuid := 'ee555555-eeee-eeee-eeee-eeeeeeeeeeee';
  v_gc_old  uuid := 'a1111111-1111-1111-1111-111111111111';
  v_gc_yng  uuid := 'a2222222-2222-2222-2222-222222222222';
  v_gt_old  uuid := 'b1111111-1111-1111-1111-111111111111';
  v_gt_yng  uuid := 'b2222222-2222-2222-2222-222222222222';
  v_j       jsonb;
  v_state   text;
  v_ls      text;
  v_end     timestamptz;
BEGIN
  -- Gc-old: created 30h ago → discard
  INSERT INTO games (
    game_id,
    game_name,
    game_security,
    is_ranked,
    game_max_players,
    joining_code,
    end_condition,
    admin_player_id,
    game_state,
    game_created_at,
    updated_at,
    state_version
  ) VALUES (
    v_gc_old,
    'Stale Created',
    'public',
    'casual',
    4,
    'STLC1',
    'endless',
    v_admin,
    'created',
    clock_timestamp() - interval '30 hours',
    clock_timestamp() - interval '1 hour',
    1
  );

  INSERT INTO games_players (
    map_game_id,
    map_player_id,
    lobby_status,
    is_admin,
    delta_cash,
    delta_envelopes,
    pnl
  ) VALUES (
    v_gc_old,
    v_admin,
    'ready',
    true,
    0,
    0,
    0
  );

  -- Gc-young: created 30h ago but only 10h since creation... use 10h created
  INSERT INTO games (
    game_id,
    game_name,
    game_security,
    is_ranked,
    game_max_players,
    joining_code,
    end_condition,
    admin_player_id,
    game_state,
    game_created_at,
    state_version
  ) VALUES (
    v_gc_yng,
    'Young Created',
    'public',
    'casual',
    4,
    'STLC2',
    'endless',
    v_admin,
    'created',
    clock_timestamp() - interval '10 hours',
    1
  );

  -- Gt-old: trading_started, updated_at 40h ago → trading_ended
  INSERT INTO games (
    game_id,
    game_name,
    game_security,
    is_ranked,
    game_max_players,
    joining_code,
    end_condition,
    admin_player_id,
    game_state,
    start_time,
    updated_at,
    state_version
  ) VALUES (
    v_gt_old,
    'Stale Trading',
    'public',
    'casual',
    4,
    'STLT1',
    'endless',
    v_admin,
    'trading_started',
    clock_timestamp() - interval '48 hours',
    clock_timestamp() - interval '40 hours',
    5
  );

  INSERT INTO games_players (
    map_game_id,
    map_player_id,
    lobby_status,
    is_admin,
    delta_cash,
    delta_envelopes,
    pnl
  ) VALUES (
    v_gt_old,
    v_admin,
    'playing',
    true,
    0,
    0,
    0
  );

  -- Gt-young: trading_started, updated_at 10h ago → unchanged
  INSERT INTO games (
    game_id,
    game_name,
    game_security,
    is_ranked,
    game_max_players,
    joining_code,
    end_condition,
    admin_player_id,
    game_state,
    start_time,
    updated_at,
    state_version
  ) VALUES (
    v_gt_yng,
    'Active Trading',
    'public',
    'casual',
    4,
    'STLT2',
    'endless',
    v_admin,
    'trading_started',
    clock_timestamp() - interval '12 hours',
    clock_timestamp() - interval '10 hours',
    2
  );

  v_j := public.sweeper_stale_created_games();
  IF (v_j ->> 'stale_created_discarded')::bigint <> 1 THEN
    RAISE EXCEPTION 'FAIL: expected 1 stale created discarded, got %', v_j;
  END IF;

  SELECT game_state INTO v_state FROM games WHERE game_id = v_gc_old;
  IF v_state <> 'discarded' THEN
    RAISE EXCEPTION 'FAIL: Gc-old expected discarded, got %', v_state;
  END IF;

  SELECT lobby_status INTO v_ls
  FROM games_players WHERE map_game_id = v_gc_old AND map_player_id = v_admin;
  IF v_ls <> 'finished' THEN
    RAISE EXCEPTION 'FAIL: Gc-old player expected finished, got %', v_ls;
  END IF;

  SELECT game_state INTO v_state FROM games WHERE game_id = v_gc_yng;
  IF v_state <> 'created' THEN
    RAISE EXCEPTION 'FAIL: Gc-young should stay created, got %', v_state;
  END IF;

  v_j := public.sweeper_stale_trading_started_games();
  IF (v_j ->> 'stale_trading_started_ended')::bigint <> 1 THEN
    RAISE EXCEPTION 'FAIL: expected 1 stale trading_started ended, got %', v_j;
  END IF;

  SELECT game_state, end_time_actual
  INTO v_state, v_end
  FROM games WHERE game_id = v_gt_old;
  IF v_state <> 'trading_ended' THEN
    RAISE EXCEPTION 'FAIL: Gt-old expected trading_ended, got %', v_state;
  END IF;
  IF v_end IS NULL THEN
    RAISE EXCEPTION 'FAIL: Gt-old expected end_time_actual set';
  END IF;

  SELECT game_state INTO v_state FROM games WHERE game_id = v_gt_yng;
  IF v_state <> 'trading_started' THEN
    RAISE EXCEPTION 'FAIL: Gt-young should stay trading_started, got %', v_state;
  END IF;
END;
$sweep17$;

ROLLBACK;
