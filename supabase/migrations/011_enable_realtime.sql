-- ============================================================================
-- Migration: 011_enable_realtime
-- Stream A / A11: expose gameplay tables to Supabase Realtime
--
-- Supabase hosts a `supabase_realtime` publication; clients subscribe with
-- row filters in Stream B (column names are per-table):
--   - `games`:   filter `game_id=eq.<uuid>`
--   - `games_players`: filter `map_game_id=eq.<uuid>`
--   - `orders`:  filter `game_id=eq.<uuid>`
--   - `executions`: filter `executions_game_id=eq.<uuid>`
-- See `gaps-stream-a.md` (Stream B — Realtime subscription contract).
--
-- Idempotent: skips tables already present in the publication.
-- ============================================================================

DO $realtime$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['games', 'games_players', 'orders', 'executions']
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = t
    ) THEN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',
        t
      );
    END IF;
  END LOOP;
END
$realtime$;
