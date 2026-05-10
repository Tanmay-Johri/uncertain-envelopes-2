-- ============================================================================
-- Migration: 014_lookup_player_email_by_username
-- Username-based login reads `players.email` before Auth has a JWT, so the
-- anon PostgREST role cannot use a direct SELECT (RLS: players only for
-- authenticated). This RPC runs as SECURITY DEFINER and returns the email
-- for sign-in resolution only.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.lookup_player_email_by_username(p_username text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT p.email::text
  FROM public.players p
  WHERE p.username = lower(trim(p_username))
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.lookup_player_email_by_username(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lookup_player_email_by_username(text)
  TO anon, authenticated;
