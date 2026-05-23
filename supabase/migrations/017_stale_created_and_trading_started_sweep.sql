-- ============================================================================
-- Migration: 017_stale_created_and_trading_started_sweep
--
-- Additional sweeper TTL rules (invoked from sweeper_run each cron tick):
--
--   * created for 24+ hours (since game_created_at) → discarded
--   * trading_started with no games-row update for 36+ hours (updated_at) →
--     trading_ended (same order close + end_time_actual as process_end_trading)
-- ============================================================================

CREATE INDEX IF NOT EXISTS games_created_ttl_sweep_idx
  ON games (game_created_at)
  WHERE game_state = 'created';


CREATE INDEX IF NOT EXISTS games_trading_started_idle_sweep_idx
  ON games (updated_at)
  WHERE game_state = 'trading_started';


CREATE OR REPLACE FUNCTION public.sweeper_stale_created_games()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  r              RECORD;
  v_discarded    bigint := 0;
  v_game_updates integer;
BEGIN
  FOR r IN
    SELECT g.game_id
    FROM games g
    WHERE g.game_state = 'created'
      AND g.game_created_at + interval '24 hours' <= clock_timestamp()
    ORDER BY g.game_id
    FOR UPDATE OF g SKIP LOCKED
  LOOP
    UPDATE games
    SET
      game_state    = 'discarded',
      state_version = state_version + 1
    WHERE game_id = r.game_id
      AND game_state = 'created'
      AND game_created_at + interval '24 hours' <= clock_timestamp();
    GET DIAGNOSTICS v_game_updates = ROW_COUNT;

    IF v_game_updates = 1 THEN
      UPDATE games_players gp
      SET lobby_status = 'finished'
      WHERE gp.map_game_id = r.game_id;
      v_discarded := v_discarded + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('stale_created_discarded', v_discarded);
END;
$$;

REVOKE ALL ON FUNCTION public.sweeper_stale_created_games() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_stale_created_games() TO service_role;


CREATE OR REPLACE FUNCTION public.sweeper_stale_trading_started_games()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  r              RECORD;
  v_ended        bigint := 0;
  v_game_updates integer;
BEGIN
  FOR r IN
    SELECT g.game_id
    FROM games g
    WHERE g.game_state = 'trading_started'
      AND g.updated_at + interval '36 hours' <= clock_timestamp()
    ORDER BY g.game_id
    FOR UPDATE OF g SKIP LOCKED
  LOOP
    UPDATE orders
    SET status = 'game_ended'
    WHERE game_id = r.game_id
      AND status IN ('in_queue', 'being_processed', 'order_resting');

    UPDATE games
    SET
      game_state      = 'trading_ended',
      end_time_actual = clock_timestamp(),
      state_version   = state_version + 1
    WHERE game_id = r.game_id
      AND game_state = 'trading_started'
      AND updated_at + interval '36 hours' <= clock_timestamp();
    GET DIAGNOSTICS v_game_updates = ROW_COUNT;

    IF v_game_updates = 1 THEN
      v_ended := v_ended + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('stale_trading_started_ended', v_ended);
END;
$$;

REVOKE ALL ON FUNCTION public.sweeper_stale_trading_started_games() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_stale_trading_started_games() TO service_role;


CREATE OR REPLACE FUNCTION public.sweeper_run()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, net, pg_temp
AS $$
DECLARE
  v_rescue_rows bigint;
  v_rescue_http bigint;
  v_auto        bigint;
  v_kick        bigint;
  v_stale       jsonb;
  v_created     jsonb;
  v_started     jsonb;
BEGIN
  SELECT r.rescued_commands, r.http_kicks
  INTO   v_rescue_rows, v_rescue_http
  FROM   public.sweeper_rescue_stuck_claimed() AS r;

  v_auto := public.sweeper_auto_end_timed_games();

  v_kick := public.sweeper_kick_idle_processors();

  v_stale := public.sweeper_stale_trading_ended_games();

  v_created := public.sweeper_stale_created_games();

  v_started := public.sweeper_stale_trading_started_games();

  RETURN jsonb_build_object(
    'rescued_commands', v_rescue_rows,
    'rescued_http_kicks', v_rescue_http,
    'auto_end_inserts', v_auto,
    'idle_http_kicks', v_kick
  ) || v_stale || v_created || v_started;
END;
$$;

REVOKE ALL ON FUNCTION public.sweeper_run() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_run() TO service_role;

DO $grant_cron$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
    GRANT EXECUTE ON FUNCTION public.sweeper_run() TO postgres;
  END IF;
END;
$grant_cron$;
