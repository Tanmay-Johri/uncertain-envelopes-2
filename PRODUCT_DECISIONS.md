# Product decisions (cross-plan traceability)

This file links **`uncertain_envelopes_v2_phase2.plan.md`** § “Product decisions to surface” to **repo reality** and **open questions**.  
Update when product or compliance chooses a path; keep **`gaps-stream-*.md`** in sync where each gap lives.

| Topic | Plan / gap ref | Repo / implementation snapshot | Decision status |
|--------|----------------|--------------------------------|-----------------|
| Mid-`trading_started` joins for **ranked** games | A-GAP-6 | **Needs explicit product call** — verify `process_join_game` + ranked rules in `supabase/migrations/004_create_lobby_functions.sql` (or latest lobby migration) against intended UX. | **Open — confirm with stakeholder** |
| **Self-matching** (same player both sides) | A-GAP-10 | **Needs explicit product call** — inspect `match_order` / cursor predicates in order-matching migration. | **Open — confirm with stakeholder** |
| **`players.email` visibility under RLS** | A-GAP-3 | Documented in **`gaps-stream-a.md`**: today broad `SELECT` on `players`; privacy follow-up listed. | **Open — compliance / launch** |
| Username uniqueness errors vs UI mapping | `gaps-stream-c.md` / 2B.7 | Profile wiring maps repository errors in **`profile_route_screen`** / **`PlayerRepository`** path — confirm literal vs API messages match product copy. | **Review** |
| Profile stats RPC vs placeholders | B-GAP-2 | Migration **`013_player_ranked_finalised_participations.sql`** exists; **`profile_view_data_provider`** consumes RPC when backend applies migration. | **Implemented in repo — confirm remote DB migrated** |
| Game history fetch vs stub | 2B.9 | **`game_history_view_data_provider`** + repository fetch — **implemented**. | **Implemented** |
| **`submitCreateGame` return / navigation** | 2B.3 | **`GameRepository.createGameAndReturnGameId`** polls until command **`processed`** (see **`lib/data/repositories/in_memory_game_repository.dart`** / Supabase twin); **`CreateGameScreen`** navigates to lobby on success. | **Implemented — poll-then-navigate** |

When a row moves from **Open** to **Decided**, append a dated line under **Log** and update the relevant **`gaps-stream-*.md`** section.

## Log

| Date | Change |
|------|--------|
| 2026-05-10 | File created; snapshot from codebase review (agent). |
