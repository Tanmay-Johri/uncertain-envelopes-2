-- ============================================================================
-- Migration: 016_trading_ended_ttl_sweep
--
-- Games stuck in trading_ended for 24+ hours (since end_time_actual) are
-- auto-resolved by the command sweeper:
--   * envelope_price IS NOT NULL → finalise (same PnL write as process_finalise_game)
--   * envelope_price IS NULL     → discard (same lobby/game transition as process_discard_game)
--
-- Uses end_time_actual (set when trading ends) as the start of the 24h window.
-- Rows with NULL end_time_actual are skipped (defensive).
-- ============================================================================

CREATE INDEX IF NOT EXISTS games_trading_ended_ttl_sweep_idx
  ON games (end_time_actual)
  WHERE game_state = 'trading_ended' AND end_time_actual IS NOT NULL;


CREATE OR REPLACE FUNCTION public.sweeper_stale_trading_ended_games()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  r              RECORD;
  v_finalised    bigint := 0;
  v_discarded    bigint := 0;
  v_game_updates integer;
BEGIN
  FOR r IN
    SELECT g.game_id, g.envelope_price
    FROM games g
    WHERE g.game_state = 'trading_ended'
      AND g.end_time_actual IS NOT NULL
      AND g.end_time_actual + interval '24 hours' <= clock_timestamp()
    ORDER BY g.game_id
    FOR UPDATE OF g SKIP LOCKED
  LOOP
    IF r.envelope_price IS NOT NULL THEN
      UPDATE games
      SET
        game_state    = 'game_finalised',
        state_version = state_version + 1
      WHERE game_id = r.game_id
        AND game_state = 'trading_ended'
        AND end_time_actual IS NOT NULL
        AND end_time_actual + interval '24 hours' <= clock_timestamp()
        AND envelope_price IS NOT NULL;
      GET DIAGNOSTICS v_game_updates = ROW_COUNT;

      IF v_game_updates = 1 THEN
        UPDATE games_players gp
        SET
          pnl          = round(
            gp.delta_cash + r.envelope_price * gp.delta_envelopes,
            5
          ),
          lobby_status = 'finished'
        WHERE gp.map_game_id = r.game_id;
        v_finalised := v_finalised + 1;
      END IF;
    ELSE
      UPDATE games
      SET
        game_state    = 'discarded',
        state_version = state_version + 1
      WHERE game_id = r.game_id
        AND game_state = 'trading_ended'
        AND end_time_actual IS NOT NULL
        AND end_time_actual + interval '24 hours' <= clock_timestamp()
        AND envelope_price IS NULL;
      GET DIAGNOSTICS v_game_updates = ROW_COUNT;

      IF v_game_updates = 1 THEN
        UPDATE games_players gp
        SET lobby_status = 'finished'
        WHERE gp.map_game_id = r.game_id;
        v_discarded := v_discarded + 1;
      END IF;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'stale_trading_ended_finalised', v_finalised,
    'stale_trading_ended_discarded', v_discarded
  );
END;
$$;

REVOKE ALL ON FUNCTION public.sweeper_stale_trading_ended_games() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_stale_trading_ended_games() TO service_role;


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
BEGIN
  SELECT r.rescued_commands, r.http_kicks
  INTO   v_rescue_rows, v_rescue_http
  FROM   public.sweeper_rescue_stuck_claimed() AS r;

  v_auto := public.sweeper_auto_end_timed_games();

  v_kick := public.sweeper_kick_idle_processors();

  v_stale := public.sweeper_stale_trading_ended_games();

  RETURN jsonb_build_object(
    'rescued_commands', v_rescue_rows,
    'rescued_http_kicks', v_rescue_http,
    'auto_end_inserts', v_auto,
    'idle_http_kicks', v_kick
  ) || v_stale;
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
