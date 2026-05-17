-- ============================================================================
-- Test: trading_ended_ttl_sweep_test
-- Verifies sweeper_stale_trading_ended_games auto-finalises or discards games
-- that have been in trading_ended for 24+ hours (since end_time_actual).
-- ============================================================================

BEGIN;

INSERT INTO auth.users (id, email) VALUES
  ('dd444444-dddd-dddd-dddd-dddddddddddd', 'ttl@a16.test');

INSERT INTO players (player_id, username, email) VALUES
  ('dd444444-dddd-dddd-dddd-dddddddddddd', 'ttladmin', 'ttl@a16.test');

DO $ttl$
DECLARE
  v_admin uuid := 'dd444444-dddd-dddd-dddd-dddddddddddd';
  v_g1    uuid := 'f1111111-1111-1111-1111-111111111111';
  v_g2    uuid := 'f2222222-2222-2222-2222-222222222222';
  v_j     jsonb;
  v_state text;
  v_pnl   numeric;
BEGIN
  -- G1: trading_ended 30h ago, envelope set → should finalise
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
    end_time_actual,
    envelope_price,
    state_version
  ) VALUES (
    v_g1,
    'TTL Final',
    'public',
    'casual',
    4,
    'TTLF1',
    'endless',
    v_admin,
    'trading_ended',
    clock_timestamp() - interval '30 hours',
    88.5,
    3
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
    v_g1,
    v_admin,
    'playing',
    true,
    100,
    -2,
    0
  );

  -- G2: trading_ended 30h ago, no envelope → should discard
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
    end_time_actual,
    envelope_price,
    state_version
  ) VALUES (
    v_g2,
    'TTL Discard',
    'public',
    'casual',
    4,
    'TTLF2',
    'endless',
    v_admin,
    'trading_ended',
    clock_timestamp() - interval '30 hours',
    NULL,
    2
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
    v_g2,
    v_admin,
    'playing',
    true,
    0,
    0,
    0
  );

  v_j := public.sweeper_stale_trading_ended_games();

  IF (v_j ->> 'stale_trading_ended_finalised')::bigint <> 1 THEN
    RAISE EXCEPTION 'FAIL: expected 1 finalised, got %', v_j ->> 'stale_trading_ended_finalised';
  END IF;
  IF (v_j ->> 'stale_trading_ended_discarded')::bigint <> 1 THEN
    RAISE EXCEPTION 'FAIL: expected 1 discarded, got %', v_j ->> 'stale_trading_ended_discarded';
  END IF;

  SELECT game_state INTO v_state FROM games WHERE game_id = v_g1;
  IF v_state <> 'game_finalised' THEN
    RAISE EXCEPTION 'FAIL: G1 expected game_finalised, got %', v_state;
  END IF;

  SELECT pnl INTO v_pnl FROM games_players WHERE map_game_id = v_g1 AND map_player_id = v_admin;
  IF v_pnl <> round(100::numeric + 88.5 * (-2), 5) THEN
    RAISE EXCEPTION 'FAIL: G1 pnl expected %, got %',
      round(100::numeric + 88.5 * (-2), 5),
      v_pnl;
  END IF;

  SELECT game_state INTO v_state FROM games WHERE game_id = v_g2;
  IF v_state <> 'discarded' THEN
    RAISE EXCEPTION 'FAIL: G2 expected discarded, got %', v_state;
  END IF;

  -- G3: trading_ended only 1h ago → must not be touched
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
    end_time_actual,
    envelope_price,
    state_version
  ) VALUES (
    'f3333333-3333-3333-3333-333333333333',
    'TTL Young',
    'public',
    'casual',
    4,
    'TTLF3',
    'endless',
    v_admin,
    'trading_ended',
    clock_timestamp() - interval '1 hour',
    10,
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
    'f3333333-3333-3333-3333-333333333333',
    v_admin,
    'playing',
    true,
    0,
    0,
    0
  );

  v_j := public.sweeper_stale_trading_ended_games();
  IF (v_j ->> 'stale_trading_ended_finalised')::bigint <> 0
     OR (v_j ->> 'stale_trading_ended_discarded')::bigint <> 0 THEN
    RAISE EXCEPTION 'FAIL: young trading_ended game should not sweep, got %', v_j;
  END IF;

  SELECT game_state INTO v_state FROM games WHERE game_id = 'f3333333-3333-3333-3333-333333333333';
  IF v_state <> 'trading_ended' THEN
    RAISE EXCEPTION 'FAIL: G3 should stay trading_ended, got %', v_state;
  END IF;
END;
$ttl$;

ROLLBACK;
