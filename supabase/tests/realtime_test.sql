-- ============================================================================
-- Test: realtime_test
-- Stream A / A11-TEST: publication membership for Supabase Realtime
--
-- Asserts that `games`, `games_players`, `orders`, and `executions` are
-- listed in `pg_publication_tables` for `supabase_realtime`. This proves the
-- migration ran; end-to-end WebSocket delivery is validated in Phase 2 INT3
-- (Flutter + GameRealtimeService).
--
-- Run after migrations 001–011 are applied (e.g. `supabase db reset` or remote
-- `apply_migration`). Fails fast with a clear RAISE if any table is missing.
-- ============================================================================

DO $realtime_test$
DECLARE
  v_missing text[];
BEGIN
  SELECT array_agg(t.tablename ORDER BY t.tablename)
  INTO v_missing
  FROM (
    VALUES
      ('games'),
      ('games_players'),
      ('orders'),
      ('executions')
  ) AS t(tablename)
  WHERE NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables p
    WHERE p.pubname = 'supabase_realtime'
      AND p.schemaname = 'public'
      AND p.tablename = t.tablename
  );

  IF v_missing IS NOT NULL AND cardinality(v_missing) > 0 THEN
    RAISE EXCEPTION 'A11 realtime_test: missing from supabase_realtime publication: %',
      v_missing;
  END IF;

  RAISE NOTICE 'A11 realtime_test: OK — games, games_players, orders, executions are in supabase_realtime';
END
$realtime_test$;
