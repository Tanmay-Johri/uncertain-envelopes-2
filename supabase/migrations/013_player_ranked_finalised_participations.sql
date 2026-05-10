-- ============================================================================
-- Migration: 013_player_ranked_finalised_participations
-- RPC for profile ranked stats (B-GAP-2). Called from Dart via
-- RealSupabasePlayerGateway.fetchRankedFinalisedGameParticipations.
--
-- Returns one row per ranked + game_finalised seat for the given player,
-- with that seat's pnl and the max pnl in that game (tie semantics for wins
-- are decided client-side: pnl >= top_pnl_in_game).
--
-- Runs as SECURITY INVOKER so RLS on games / games_players applies; callers
-- only see rows for games they could already read as members.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.player_ranked_finalised_participations(
  p_player_id uuid
)
RETURNS TABLE (
  map_game_id uuid,
  pnl numeric,
  top_pnl_in_game numeric
)
LANGUAGE sql
STABLE
SET search_path = public, pg_temp
AS $$
  SELECT
    gp.map_game_id,
    gp.pnl::numeric AS pnl,
    mx.top_pnl_in_game::numeric AS top_pnl_in_game
  FROM public.games_players gp
  INNER JOIN public.games g ON g.game_id = gp.map_game_id
  INNER JOIN (
    SELECT
      gp2.map_game_id,
      MAX(gp2.pnl) AS top_pnl_in_game
    FROM public.games_players gp2
    INNER JOIN public.games g2 ON g2.game_id = gp2.map_game_id
    WHERE g2.is_ranked = 'ranked'
      AND g2.game_state = 'game_finalised'
    GROUP BY gp2.map_game_id
  ) mx ON mx.map_game_id = gp.map_game_id
  WHERE gp.map_player_id = p_player_id
    AND g.is_ranked = 'ranked'
    AND g.game_state = 'game_finalised';
$$;

REVOKE ALL ON FUNCTION public.player_ranked_finalised_participations(uuid)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.player_ranked_finalised_participations(uuid)
  TO authenticated, service_role;
