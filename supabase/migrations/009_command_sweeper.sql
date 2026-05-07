-- ============================================================================
-- Migration: 009_command_sweeper (part 1 of 2 — see 010 for kick/run/cron)
-- Stream A / A9: sweeper core — pg_net invoke helper, stuck-claim rescue,
-- timed auto-end inserts.
-- ============================================================================

DO $ext$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_cron;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'pg_cron extension skipped: % (SQLSTATE %)', SQLERRM, SQLSTATE;
END;
$ext$;

CREATE OR REPLACE FUNCTION public.sweeper_invoke_command_processor(
  p_command_id uuid,
  p_command_game_id uuid
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, net, pg_temp
AS $$
DECLARE
  v_url    text;
  v_anon   text;
  v_secret text;
  v_body   jsonb;
  v_req    bigint;
BEGIN
  SELECT ds.decrypted_secret INTO v_url
  FROM   vault.decrypted_secrets AS ds
  WHERE  ds.name = 'command_processor_url'
  LIMIT  1;

  SELECT ds.decrypted_secret INTO v_anon
  FROM   vault.decrypted_secrets AS ds
  WHERE  ds.name = 'command_processor_anon_key'
  LIMIT  1;

  SELECT ds.decrypted_secret INTO v_secret
  FROM   vault.decrypted_secrets AS ds
  WHERE  ds.name = 'command_processor_webhook_secret'
  LIMIT  1;

  IF v_url IS NULL OR v_anon IS NULL OR v_secret IS NULL THEN
    RAISE WARNING 'sweeper_invoke_command_processor: vault secrets missing (command_processor_url / command_processor_anon_key / command_processor_webhook_secret) — skipping HTTP for command %',
      p_command_id;
    RETURN NULL;
  END IF;

  v_body := jsonb_build_object(
    'command_id',      p_command_id,
    'command_game_id', p_command_game_id
  );

  SELECT net.http_post(
    url     := v_url,
    body    := v_body,
    params  := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || v_secret,
      'apikey',        v_anon
    ),
    timeout_milliseconds := 5000
  ) INTO v_req;

  RETURN v_req;
END;
$$;

REVOKE ALL ON FUNCTION public.sweeper_invoke_command_processor(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_invoke_command_processor(uuid, uuid) TO service_role;


CREATE OR REPLACE FUNCTION public.sweeper_rescue_stuck_claimed()
RETURNS TABLE (rescued_commands bigint, http_kicks bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, net, pg_temp
AS $$
DECLARE
  r         RECORD;
  v_rescued bigint := 0;
  v_kicks   bigint := 0;
  v_req     bigint;
BEGIN
  CREATE TEMP TABLE IF NOT EXISTS sweeper_rescue_batch (
    command_id       uuid NOT NULL,
    command_game_id  uuid
  ) ON COMMIT DROP;

  TRUNCATE sweeper_rescue_batch;

  WITH rescued AS (
    UPDATE commands c
    SET    command_status = 'failed',
           claim_token    = NULL,
           claimed_at     = NULL
    WHERE  c.command_status = 'claimed'
      AND  c.claimed_at IS NOT NULL
      AND  c.claimed_at < (clock_timestamp() - interval '30 seconds')
    RETURNING c.command_id, c.command_game_id
  )
  INSERT INTO sweeper_rescue_batch (command_id, command_game_id)
  SELECT r2.command_id, r2.command_game_id FROM rescued r2;

  GET DIAGNOSTICS v_rescued = ROW_COUNT;

  FOR r IN
    SELECT DISTINCT ON (COALESCE(b.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid))
      b.command_id,
      b.command_game_id
    FROM sweeper_rescue_batch b
    ORDER BY COALESCE(b.command_game_id, '00000000-0000-0000-0000-000000000000'::uuid), b.command_id
  LOOP
    v_req := public.sweeper_invoke_command_processor(r.command_id, r.command_game_id);
    IF v_req IS NOT NULL THEN
      v_kicks := v_kicks + 1;
    END IF;
  END LOOP;

  rescued_commands := v_rescued;
  http_kicks := v_kicks;
  RETURN NEXT;
END;
$$;

REVOKE ALL ON FUNCTION public.sweeper_rescue_stuck_claimed() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_rescue_stuck_claimed() TO service_role;


CREATE OR REPLACE FUNCTION public.sweeper_auto_end_timed_games()
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  WITH ins AS (
    INSERT INTO commands (command_game_id, command_type, player_id, payload)
    SELECT
      g.game_id,
      'end_trading'::command_type,
      NULL::uuid,
      '{}'::jsonb
    FROM games g
    WHERE g.game_state = 'trading_started'
      AND g.end_condition = 'timed'
      AND g.end_time_decided IS NOT NULL
      AND g.end_time_decided <= clock_timestamp()
      AND NOT EXISTS (
        SELECT 1
        FROM   commands c
        WHERE  c.command_game_id = g.game_id
          AND  c.command_type = 'end_trading'
          AND  c.command_status NOT IN ('processed', 'rejected')
      )
    RETURNING 1
  )
  SELECT COUNT(*)::bigint FROM ins;
$$;

REVOKE ALL ON FUNCTION public.sweeper_auto_end_timed_games() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sweeper_auto_end_timed_games() TO service_role;
