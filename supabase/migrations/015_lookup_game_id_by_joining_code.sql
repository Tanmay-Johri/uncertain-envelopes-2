-- ============================================================================
-- Migration: 015_lookup_game_id_by_joining_code
-- A non-member of a **private** game cannot SELECT its row via RLS, so
-- `joinByCode` returns "No game found" even with the correct code. Joining
-- by code is the canonical entry point for private games — anyone with the
-- code is allowed to learn the `game_id` and submit a `join_game` command.
--
-- This RPC runs as SECURITY DEFINER and returns ONLY the `game_id` (no
-- title, description, or membership info). The downstream `join_game`
-- procedure validates state / capacity.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.lookup_game_id_by_joining_code(p_code text)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT g.game_id
  FROM public.games g
  WHERE g.joining_code = upper(trim(p_code))
    AND g.game_state IN ('created', 'trading_started')
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.lookup_game_id_by_joining_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lookup_game_id_by_joining_code(text)
  TO authenticated;
