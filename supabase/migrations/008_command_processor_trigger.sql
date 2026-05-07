-- ============================================================================
-- Migration: 008_command_processor_trigger
-- Stream A / A8: pg_net trigger + helper RPCs for the command-processor Edge
-- Function.
--
-- Part A — Helper RPCs (SECURITY DEFINER, service_role only)
--   command_processor_has_recent_claim(p_game_id uuid)
--       Returns true when any command for this game is `claimed` with
--       claimed_at within the last 30 seconds. If p_game_id IS NULL, always
--       returns false (create_game commands have no game mutex yet).
--
--   command_processor_claim_next(p_game_id uuid)
--       Atomically claims the next eligible command for the partition:
--         * If p_game_id IS NULL: command_game_id IS NULL (only create_game).
--         * Else: command_game_id = p_game_id.
--       Eligible means: pending OR (failed AND attempt_count < 3).
--       Sets status=claimed, fresh claim_token, claimed_at=now(),
--       attempt_count += 1. Uses FOR UPDATE SKIP LOCKED.
--       Returns a slim row projection (one row) or nothing.
--
--   command_processor_mark_processed / _failed / _rejected
--       Terminalisation helpers that only succeed when claim_token matches
--       and status is still `claimed`. Returns boolean (true = row updated).
--
-- Part B — pg_net AFTER INSERT trigger on public.commands
--   Reads three secrets from vault.decrypted_secrets (create these with
--   vault.create_secret after first deploy — see footer comment):
--     1. command_processor_url         — full URL, e.g.
--        https://<ref>.supabase.co/functions/v1/command-processor
--     2. command_processor_anon_key    — Supabase anon (publishable) key for
--        the `apikey` header (platform layer).
--     3. command_processor_webhook_secret — long random string; must match
--        Edge Function secret COMMAND_PROCESSOR_WEBHOOK_SECRET.
--
--   Fire-and-forget net.http_post (executes after transaction commit).
--
-- pg_net + vault are available on Supabase projects; extension create may
-- require elevated rights — runs as migration owner.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ---------------------------------------------------------------------------
-- Helper: recent active claim (30s game-level mutex)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.command_processor_has_recent_claim(p_game_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    CASE WHEN p_game_id IS NULL THEN false
    ELSE EXISTS (
      SELECT 1
      FROM   commands c
      WHERE  c.command_game_id = p_game_id
        AND  c.command_status = 'claimed'
        AND  c.claimed_at IS NOT NULL
        AND  c.claimed_at > (clock_timestamp() - interval '30 seconds')
    )
    END;
$$;

REVOKE ALL ON FUNCTION public.command_processor_has_recent_claim(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.command_processor_has_recent_claim(uuid) TO service_role;


-- ---------------------------------------------------------------------------
-- Helper: atomic claim (SKIP LOCKED)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.command_processor_claim_next(p_game_id uuid)
RETURNS TABLE (
  out_command_id    uuid,
  out_claim_token   uuid,
  out_command_type  command_type,
  out_attempt_count integer,
  out_player_id     uuid,
  out_command_game_id uuid,
  out_payload       jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  WITH picked AS (
    SELECT c.command_id
    FROM   commands c
    WHERE  (
             (p_game_id IS NULL AND c.command_game_id IS NULL)
          OR (p_game_id IS NOT NULL AND c.command_game_id = p_game_id)
           )
      AND  (
             c.command_status = 'pending'
          OR (c.command_status = 'failed' AND c.attempt_count < 3)
           )
    ORDER BY c.command_created_at ASC
    FOR UPDATE SKIP LOCKED
    LIMIT 1
  ),
  upd AS (
    UPDATE commands c
    SET    command_status = 'claimed',
           claim_token    = gen_random_uuid(),
           claimed_at     = clock_timestamp(),
           attempt_count  = c.attempt_count + 1
    FROM   picked p
    WHERE  c.command_id = p.command_id
    RETURNING
      c.command_id,
      c.claim_token,
      c.command_type,
      c.attempt_count,
      c.player_id,
      c.command_game_id,
      c.payload
  )
  SELECT
    u.command_id,
    u.claim_token,
    u.command_type,
    u.attempt_count,
    u.player_id,
    u.command_game_id,
    u.payload
  FROM upd u;
END;
$$;

REVOKE ALL ON FUNCTION public.command_processor_claim_next(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.command_processor_claim_next(uuid) TO service_role;


-- ---------------------------------------------------------------------------
-- Helper: mark terminal states (claim_token gate)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.command_processor_mark_processed(
  p_command_id uuid,
  p_claim_token uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_n integer;
BEGIN
  UPDATE commands
  SET    command_status = 'processed',
         finished_at    = clock_timestamp(),
         claim_token    = NULL,
         claimed_at     = NULL
  WHERE  command_id     = p_command_id
    AND  claim_token    = p_claim_token
    AND  command_status = 'claimed';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END;
$$;

REVOKE ALL ON FUNCTION public.command_processor_mark_processed(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.command_processor_mark_processed(uuid, uuid) TO service_role;


CREATE OR REPLACE FUNCTION public.command_processor_mark_failed(
  p_command_id uuid,
  p_claim_token uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_n integer;
BEGIN
  UPDATE commands
  SET    command_status = 'failed',
         claim_token    = NULL,
         claimed_at     = NULL
  WHERE  command_id     = p_command_id
    AND  claim_token    = p_claim_token
    AND  command_status = 'claimed';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END;
$$;

REVOKE ALL ON FUNCTION public.command_processor_mark_failed(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.command_processor_mark_failed(uuid, uuid) TO service_role;


CREATE OR REPLACE FUNCTION public.command_processor_mark_rejected(
  p_command_id uuid,
  p_claim_token uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_n integer;
BEGIN
  UPDATE commands
  SET    command_status = 'rejected',
         finished_at    = clock_timestamp(),
         claim_token    = NULL,
         claimed_at     = NULL
  WHERE  command_id     = p_command_id
    AND  claim_token    = p_claim_token
    AND  command_status = 'claimed';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END;
$$;

REVOKE ALL ON FUNCTION public.command_processor_mark_rejected(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.command_processor_mark_rejected(uuid, uuid) TO service_role;


-- ---------------------------------------------------------------------------
-- Trigger: notify command-processor Edge Function
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_command_processor()
RETURNS trigger
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
    RAISE WARNING 'notify_command_processor: vault secrets missing (command_processor_url / command_processor_anon_key / command_processor_webhook_secret) — command % left pending',
      NEW.command_id;
    RETURN NEW;
  END IF;

  v_body := jsonb_build_object(
    'command_id',      NEW.command_id,
    'command_game_id', NEW.command_game_id
  );

  -- Fire-and-forget; pg_net runs the HTTP call after this transaction commits.
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

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_commands_notify_processor ON public.commands;
CREATE TRIGGER trg_commands_notify_processor
  AFTER INSERT ON public.commands
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_command_processor();

-- NOTE: one-time vault setup (run in SQL editor as superuser / dashboard):
--
-- select vault.create_secret(
--   'https://YOUR_REF.supabase.co/functions/v1/command-processor',
--   'command_processor_url',
--   'Full HTTPS URL for the command-processor Edge Function'
-- );
-- select vault.create_secret(
--   'YOUR_SUPABASE_PUBLISHABLE_ANON_KEY',
--   'command_processor_anon_key',
--   'Anon/publishable key for apikey header when invoking Edge Function'
-- );
-- select vault.create_secret(
--   'YOUR_LONG_RANDOM_SHARED_SECRET',
--   'command_processor_webhook_secret',
--   'Matches COMMAND_PROCESSOR_WEBHOOK_SECRET in Edge Function dashboard'
-- );
