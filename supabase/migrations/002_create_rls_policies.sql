-- ============================================================================
-- Migration: 002_create_rls_policies
-- Stream A / A2: row-level security for the six public tables
--
-- Design decisions (confirmed with user before writing):
--   players:        any authenticated user may SELECT any row (all columns);
--                   INSERT / UPDATE restricted to own row (player_id = auth.uid()).
--                   No DELETE policy (accounts are deleted via an explicit
--                   service-role workflow that first anonymises/soft-deletes).
--
--   games:          SELECT allowed if the current user is a member of the game
--                   OR the game is public AND in an active state
--                   (game_state IN ('created','trading_started')).
--                   No INSERT/UPDATE/DELETE policy -> writes only via stored
--                   procedures running on service_role (bypasses RLS).
--
--   games_players:  SELECT allowed if the current user is a member of the game
--                   OR the game is public AND in an active state (so the home
--                   screen can render avatar stacks without joining first).
--                   No INSERT/UPDATE/DELETE policy -> writes only via stored
--                   procedures.
--
--   orders:         SELECT allowed if the current user is a member of the game.
--                   No INSERT/UPDATE/DELETE policy -> writes only via stored
--                   procedures.
--
--   executions:     SELECT allowed if the current user is a member of the game.
--                   No INSERT/UPDATE/DELETE policy.
--
--   commands:       SELECT allowed only to the submitter (player_id = auth.uid()).
--                   INSERT allowed if player_id = auth.uid() (business rules
--                   validated inside the stored procedures). No UPDATE/DELETE
--                   policy -> mutations come from the processor (service_role).
--
-- All background workers (command processor, sweeper, cron jobs, data
-- migrations) authenticate with the service_role key, which bypasses RLS, so
-- the restrictive policy set above only applies to logged-in end users.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Helper: is_game_member(game_id)
--
-- SECURITY DEFINER so it can read games_players without triggering RLS on
-- that same table (which would cause either recursion or self-denial when
-- called from inside the games_players SELECT policy). search_path pinned to
-- public, pg_temp to prevent search-path injection per Postgres best
-- practice for SECURITY DEFINER functions.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_game_member(p_game_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.games_players
    WHERE map_game_id = p_game_id
      AND map_player_id = auth.uid()
  );
$$;

-- Do not let ordinary roles redefine or alter this helper.
REVOKE ALL ON FUNCTION public.is_game_member(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_game_member(uuid) TO authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.players       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.executions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commands      ENABLE ROW LEVEL SECURITY;

-- Tighten write-default so no UPDATE/DELETE leaks through anywhere we forget
-- a policy. (Postgres default already denies when RLS is on and no policy
-- matches; this is purely belt-and-suspenders.)
ALTER TABLE public.players       FORCE ROW LEVEL SECURITY;
ALTER TABLE public.games         FORCE ROW LEVEL SECURITY;
ALTER TABLE public.games_players FORCE ROW LEVEL SECURITY;
ALTER TABLE public.orders        FORCE ROW LEVEL SECURITY;
ALTER TABLE public.executions    FORCE ROW LEVEL SECURITY;
ALTER TABLE public.commands      FORCE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- players
-- ---------------------------------------------------------------------------
CREATE POLICY players_select_any_authenticated
  ON public.players
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY players_insert_self
  ON public.players
  FOR INSERT
  TO authenticated
  WITH CHECK (player_id = auth.uid());

CREATE POLICY players_update_self
  ON public.players
  FOR UPDATE
  TO authenticated
  USING (player_id = auth.uid())
  WITH CHECK (player_id = auth.uid());

-- ---------------------------------------------------------------------------
-- games
-- ---------------------------------------------------------------------------
CREATE POLICY games_select_member_or_public_active
  ON public.games
  FOR SELECT
  TO authenticated
  USING (
    public.is_game_member(game_id)
    OR (
      game_security = 'public'
      AND game_state IN ('created', 'trading_started')
    )
  );

-- ---------------------------------------------------------------------------
-- games_players
-- ---------------------------------------------------------------------------
CREATE POLICY games_players_select_member_or_public_active
  ON public.games_players
  FOR SELECT
  TO authenticated
  USING (
    public.is_game_member(map_game_id)
    OR EXISTS (
      SELECT 1
      FROM public.games g
      WHERE g.game_id = games_players.map_game_id
        AND g.game_security = 'public'
        AND g.game_state IN ('created', 'trading_started')
    )
  );

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
CREATE POLICY orders_select_game_member
  ON public.orders
  FOR SELECT
  TO authenticated
  USING (public.is_game_member(game_id));

-- ---------------------------------------------------------------------------
-- executions
-- ---------------------------------------------------------------------------
CREATE POLICY executions_select_game_member
  ON public.executions
  FOR SELECT
  TO authenticated
  USING (public.is_game_member(executions_game_id));

-- ---------------------------------------------------------------------------
-- commands
-- ---------------------------------------------------------------------------
CREATE POLICY commands_select_self
  ON public.commands
  FOR SELECT
  TO authenticated
  USING (player_id = auth.uid());

CREATE POLICY commands_insert_self
  ON public.commands
  FOR INSERT
  TO authenticated
  WITH CHECK (player_id = auth.uid());
