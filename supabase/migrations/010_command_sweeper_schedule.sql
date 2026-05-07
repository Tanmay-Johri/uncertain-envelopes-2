-- ============================================================================
-- Migration: 010_command_sweeper_schedule (part 2 of 2 — depends on 009)
-- Stream A / A9: idle kicks, sweeper_run orchestrator, pg_cron schedule.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.sweeper_kick_idle_processors()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, net, pg_temp
AS $$
DECLARE
  r       RECORD;
  v_kicks bigint := 0;
  v_req   bigint;
BEGIN
  FOR r IN
    SELECT DISTINCT ON (COALESCE(c.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid))
      c.command_id,
      c.command_game_id
    FROM commands c
    WHERE (
            c.command_status = 'pending'
         OR (c.command_status = 'failed' AND c.attempt_count < 3)
          )
      AND NOT public.command_processor_has_recent_claim(c.command_game_id)
    ORDER BY COALESCE(c.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid), c.command_created_at ASC
  LOOP
    v_req := public.sweeper_invoke_command_processor(r.command_id, r.command_game_id);
    IF v_req IS NOT NULL THEN
      v_kicks := v_kicks + 1;
    END IF;
  END LOOP;

  RETURN v_kicks;
END;
$$;

REVOKE ALL ON FUNCTION public.sweeper_kick_idle_processors() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_kick_idle_processors() TO service_role;


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
BEGIN
  SELECT r.rescued_commands, r.http_kicks
  INTO   v_rescue_rows, v_rescue_http
  FROM   public.sweeper_rescue_stuck_claimed() AS r;

  v_auto := public.sweeper_auto_end_timed_games();

  v_kick := public.sweeper_kick_idle_processors();

  RETURN jsonb_build_object(
    'rescued_commands', v_rescue_rows,
    'rescued_http_kicks', v_rescue_http,
    'auto_end_inserts', v_auto,
    'idle_http_kicks', v_kick
  );
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


DO $cron$
DECLARE
  j record;
BEGIN
  FOR j IN
    SELECT jobid FROM cron.job WHERE jobname = 'ue2_command_sweeper'
  LOOP
    PERFORM cron.unschedule(j.jobid);
  END LOOP;

  PERFORM cron.schedule(
    'ue2_command_sweeper',
    '* * * * *',
    'SELECT public.sweeper_run()'
  );
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'ue2_command_sweeper cron schedule skipped: % (SQLSTATE %)',
      SQLERRM, SQLSTATE;
END;
$cron$;
