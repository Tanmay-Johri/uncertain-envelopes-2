# Stream A — Known Gaps

Gaps deliberately left open or deferred during Phase 1 Stream A (backend
SQL, RLS, stored procedures, Edge Functions, Redis, Realtime). Each item is
either test coverage we did not fully achieve, defense-in-depth that cannot
be exercised via the supported ingress path, or a product/schema contract
that needs a cross-stream decision before tightening.

Close during **Phase 2 (Integration)** after merging `stream-a`, `stream-b`,
and `stream-c` into `main`, by reading this file beside:

- `gaps-stream-b.md`
- `gaps-stream-c.md`

Tracked gap IDs: `A-GAP-1` … `A-GAP-8`.

---

## A-GAP-1 — `process_create_game`: defensive `NOT EXISTS (players)` branch is unreachable via normal ingress

**Where:** `supabase/migrations/003_create_game_function.sql` — after loading
the command row, the procedure checks that `v_cmd.player_id` exists in
`public.players` before proceeding.

**Why it is unreachable today:** `commands.player_id` has a foreign key to
`players(player_id)` (`001_create_tables.sql`). Any malformed command whose
`player_id` is not in `players` fails at `INSERT INTO commands` with
sqlstate `23503` before `process_create_game` runs.

**Why we kept the check:** Defense-in-depth if the FK is ever relaxed,
deferred inserts, or maintenance scripts bypass normal ingress. If it
fires, raising `UE001` gives the processor a clean non-retriable path.

**What to do:**

1. **Leave as-is (recommended)** — zero schema change; document only
   (this file).
2. **OR** add a one-off test that drops the FK inside `BEGIN/ROLLBACK`,
   inserts an invalid `commands` row, calls `process_create_game`, asserts
   `UE001`, then restores the FK — heavy-handed for dead code.
3. **OR** delete the `NOT EXISTS` block and rely solely on the FK — fewer
   lines, slightly weaker if someone breaks the FK later.

**Priority:** Low — correctness of the happy path is fully FK-guaranteed.

---

## A-GAP-2 — Joining-code collision retry loop is not deterministically tested

**Where:** `process_create_game` — inner `LOOP` that generates random
5-character `[A-Z0-9]` codes, `INSERT INTO games`, catches
`unique_violation`, retries up to 50 times.

**What is tested:** `create_game_test.sql` bulk-creates 20 games and asserts
all 20 `joining_code` values are distinct. That exercises happy-path
inserts almost never hitting the `EXCEPTION WHEN unique_violation` branch.

**Why it matters:** The retry branch is the concurrency-correctness story
for two creators racing the same code; the branch itself is seven lines of
straightforward code but has **zero** dedicated test coverage.

**What to do:**

1. **Defer to Phase 2 INT3** — multi-session stress (optional). Same
   reasoning as A-GAP-5: concurrency needs two DB sessions.
2. **OR** deterministic harness: `SELECT setseed(<constant>)` before
   calling `process_create_game`, pre-insert an active game with the exact
   code the seeded RNG first produces, then assert the second game gets a
   *different* code (proving at least one retry path). Requires one-time
   calibration of `setseed` → first code.
3. **OR** test-only hook (not recommended): inject a fixed alphabet of
   length 1 so collisions are trivial — adds production/test divergence.

**Priority:** Low — probability of accidental collision in 20 draws is
~3×10⁻⁶; implementation is inspectable.

---

## A-GAP-3 — RLS: `players.email` is visible to every authenticated user

**Where:** `002_create_rls_policies.sql` — policy
`players_select_any_authenticated` uses `USING (true)` for `SELECT`.

**Why we chose it:** Stream B needs usernames (and player ids) for lobbies;
MVP settled on "simplest policy — full row visible."

**Risk:** Email is PII; any logged-in user can read every other player’s
email column via PostgREST.

**What to do:**

1. **Phase 2:** Replace with a view `public_players` exposing
   `player_id`, `username`, `created_at` only; grant `SELECT` on the view
   to `authenticated`; tighten `players` to `SELECT` self-only **or**
   service_role-only on `players` and route all "other users" reads through
   the view / RPC.
2. **OR** keep table-wide `SELECT` but strip `email` from anon/role via
   column-level privileges (Postgres `GRANT SELECT (player_id, username,
   …)`).

**Priority:** Medium for privacy compliance; low for gameplay correctness.

---

## A-GAP-4 — `process_join_game`: `FOR UPDATE` on `games` row is not proven under concurrent sessions

**Where:** `004_create_lobby_functions.sql` — `SELECT … FROM games … FOR
UPDATE` before counting members and inserting `games_players`.

**Purpose:** Serialize two clients simultaneously taking the last
`max_players` slot so both cannot pass the count check.

**What is tested:** Single-session SQL tests only — concurrent joins cannot
be expressed in one connection. Removing `FOR UPDATE` would **not** fail
any current Stream A test.

**What to do:**

1. **Phase 2 INT3** — open two browser tabs / two DB sessions / load test;
   assert exactly one join succeeds at the capacity boundary and the other
   receives `UE002` (game full).
2. **OR** transactional torture test using `dblink` / second connection
   from CI — high setup cost for marginal gain over code inspection.

**Priority:** Medium for production correctness under load; low until
high-concurrency lobby joins matter.

---

## A-GAP-5 — `process_leave_game` / `process_kick_player`: no `UPDATE orders` for departing players

**Where:** Both procedures `DELETE FROM games_players` only.

**Why it is OK today:** Both enforce `game_state = 'created'`. Orders are
created only after `trading_started` via `process_create_order` (A6). No
orders exist for lobby-only games, so nothing to cancel.

**Risk:** If a future PRD change allows leave/kick during `trading_started`,
or a migration leaks resting orders into `created`, dangling `orders` rows
could remain for players who no longer have a `games_players` row. FK on
`orders.created_by_player_id → players` does **not** tie an order to
membership — semantic invariant only.

**What to do:**

1. **Quick hardening (recommended):** After the successful `DELETE FROM
   games_players`, add:

   ```sql
   UPDATE orders SET status = 'game_ended'
   WHERE game_id = … AND created_by_player_id = …
     AND status IN ('in_queue','being_processed','order_resting');
   ```

   Zero rows updated in `game_state='created'` today; future-proof if
   guards change.

2. **OR** schema-level `CHECK` forbidding orders while `games.game_state =
   'created'` — invasive, probably overkill.

**Priority:** Low today; medium before any lobby rule relaxation.

---

## A-GAP-6 — Mid-`trading_started` joins + `is_ranked` has no ranked-specific rule

**Where:** `process_join_game` allows `game_state IN ('created',
'trading_started')` per PRD ("They can join the game (if the game hasn't hit
maximum number of players yet)").

**Behavior:** Late joiners get fresh `delta_cash` / `delta_envelopes` /
`pnl` zeros; PnL is only meaningful for trading after they join.
`is_ranked` is stored on `games` but no proc treats ranked games
differently for join eligibility.

**Product question:** Should **ranked** games reject joins after
`trading_started` to keep leaderboards comparable? That would **override**
current PRD text — needs explicit product sign-off.

**What to do:**

1. **No code change** if PRD stands — document for Phase 2 UX (late joiners
   see full history via snapshot repair; fairness is "same rules within
   their participation window").
2. **OR** add `IF v_game.game_state = 'trading_started' AND v_game.is_ranked =
   'ranked' THEN RAISE … UE002` in `process_join_game` once approved.

**Priority:** Product / design — not a correctness bug against current PRD.

---

## A-GAP-7 — Error-class `UE001` / `UE002` vs Postgres built-in sqlstates

**Where:** All stored procedures use custom sqlstates (`UE001`, `UE002`)
for processor routing (immediate reject vs retry).

**Risk:** Some Postgres tools / drivers surface custom sqlstates
differently; Supabase Edge (Deno) must map `err.cause.code` or equivalent
reliably in A8.

**What to do:** When implementing the command processor, add an explicit
integration test: raise `UE001` from SQL, assert the Edge function classifies
it as non-retriable without string-matching on message text.

**Priority:** Medium at A8 implementation time; not blocking earlier A-units.

---

## A-GAP-8 — Stream A units not yet built (not "bugs" — tracking for merge triage)

These are **planned** work from the master plan, not regressions:

| Unit | Missing artifact | Status |
|------|------------------|--------|
| A5 | Lifecycle procs (`start_game`, `end_trading`, `set_envelope_price`, `finalise`, `discard`, `add_time`) | ✅ **DONE** — `005_create_lifecycle_functions.sql` + `lifecycle_procs_test.sql`; full suite green |
| A6 | Order matching (`process_create_order`, `match_order`) | pending |
| A7 | `process_cancel_order` | pending |
| A8 | Edge `command-processor` + trigger wiring | pending |
| A9 | Edge `sweeper` + pg_cron | pending |
| A10 | Redis version cache + Edge `get-state-version` | pending |
| A11 | Realtime publication + client filter docs | pending |

Phase 2 should **not** try to close A-GAP-1–7 by relying on these existing;
gaps above apply to **already-shipped** migrations A1–A4.

### New gaps identified during A5 (append as A-GAP-9+)

**A-GAP-9 — `process_end_trading` system path: sweeper must supply `command_game_id`**

The schema `CHECK` constraint `commands_game_id_required_for_non_create` requires
`command_game_id IS NOT NULL` for all non-`create_game` commands. When the sweeper
inserts an `end_trading` command with `player_id = NULL`, it **must** supply a valid
`command_game_id`. This is obvious from the schema but worth documenting explicitly
so A9 (sweeper implementation) sets it correctly. The proc itself validates it (UE001
if null), so a misconfigured sweeper will produce a clean rejection rather than silent
corruption.

**Priority:** Low — the schema enforces it; this is a reminder for A9 implementation.

---

## Priority / ordering recommendation for Phase 2 (Stream A–related items only)

1. **A-GAP-5** — small defensive `UPDATE orders` in leave/kick if still
   shipping lobby rules unchanged; cheap insurance.
2. **A-GAP-3** — privacy / RLS tightening before any production launch with
   real user emails.
3. **A-GAP-4** — concurrency join test alongside INT3 multi-tab stress
   (combine with B/C realtime tests).
4. **A-GAP-6** — product decision; code is one `IF` once decided.
5. **A-GAP-7** — verify at A8 processor implementation.
6. **A-GAP-1 / A-GAP-2** — optional hygiene; acceptable to close as
   "documented only" or with targeted tests if audit requires 100 % branch
   coverage.

---

*Last updated: reflects Stream A state through A5 lifecycle procs (A-GAP-8
row updated). Next: A6 order matching. New gaps from A5: A-GAP-9.*
