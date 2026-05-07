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

Tracked gap IDs: `A-GAP-1` … `A-GAP-14` (see table + append-only sections below).

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

**Status after A8 (2026‑05‑07):** Implemented in Edge `command-processor` via structured `code`,
message/details/hint, and serialized JSON substring fallbacks (`classification.ts` +
`classification.test.ts`). **DB→Edge async integration** (raise `RAISE EXCEPTION … 'UE001'`
inside a proc, observe `commands.command_status=rejected`) is still **recommended** once
vault secrets + webhook env are wired; classify as deferred verification, not unresolved
routing logic.

**Priority:** Medium at A8 implementation time; not blocking earlier A-units.

---

## A-GAP-8 — Stream A units not yet built (not "bugs" — tracking for merge triage)

These are **planned** work from the master plan, not regressions:

| Unit | Missing artifact | Status |
|------|------------------|--------|
| A5 | Lifecycle procs (`start_game`, `end_trading`, `set_envelope_price`, `finalise`, `discard`, `add_time`) | ✅ **DONE** — `005_create_lifecycle_functions.sql` + `lifecycle_procs_test.sql`; full suite green |
| A6 | Order matching (`process_create_order`, `match_order`) | ✅ **DONE** — `006_create_order_matching.sql` + `order_matching_test.sql`; full suite green |
| A7 | `process_cancel_order` | ✅ **DONE** — `007_create_cancel_order.sql` + `cancel_order_test.sql`; full `cancel_order_test.sql` verified against linked Supabase project via MCP (`apply_migration` + `execute_sql`); local runs still supported with Docker/psql |
| A8 | Edge `command-processor` + trigger wiring | ✅ **DONE** — `008_command_processor_trigger.sql` (applied as `008_command_processor_trigger` migration) + `supabase/functions/command-processor/` + `classification.test.ts`; `verify_jwt=false`, shared-secret webhook auth, Upstash Redis fail-open sync after success |
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

### New gaps identified during A6 (append as A-GAP-10+)

**A-GAP-10 — `match_order` self-match: allowed by design, unverified UX impact**

Self-matching (a player's own resting order matched against their new incoming order)
is currently **allowed** — a deliberate design decision made during A6 planning.
No cross-stream product sign-off has been obtained. In real markets this is "wash
trading"; in a classroom/game context it may or may not matter. A6 tests do not
exercise the self-match path (every test uses alice as the incoming side and bob/carol
as resting counterparts).

**What to do:**
1. **Phase 2** — product decision: confirm allowed or prohibit. If prohibited, add
   `AND created_by_player_id <> v_order.created_by_player_id` to both cursor
   WHERE clauses in `match_order` and add a dedicated self-match test.

**Priority:** Low for gameplay correctness; medium if leaderboards / ranked mode care
about wash-trading distortion.

**A-GAP-11 — Concurrent order matching correctness not tested under load**

`match_order` uses `FOR UPDATE` on resting order rows to serialise concurrent
processors. Correctness under genuine concurrency (two `process_create_order`
calls racing the same game's order book) is not exercised by the single-session
unit tests. Removing `FOR UPDATE` would not fail any current A6 test.

**What to do:** Phase 2 INT3 — load-test with two simultaneous order submissions
to the same game; assert no duplicate execution, no double-counted delta.

**Priority:** Medium for production; low until high-concurrency order flow matters.

### New gaps identified during A7

**A-GAP-12 — `process_cancel_order`: `command_game_id IS NULL` branch is unreachable via normal INSERT**

Same pattern as **A-GAP-1**. The defensive `command_game_id` null check duplicates the schema
CHECK `commands_game_id_required_for_non_create`. Tests exercise it only by briefly dropping that
CHECK inside a rolled-back transaction (`cancel_order_test.sql` §E3).

**Priority:** Low — leave as defence-in-depth or delete the redundant `IF` if we prefer FK/CHECK-only.

**A-GAP-13 — Concurrent cancel + match on the same resting order not stress-tested**

`process_cancel_order` locks the targeted order (`SELECT … FOR UPDATE`), so correctness under a
hypothetical race with `match_order` on the same row is enforced by Postgres row locking, not proven
by a multi-session torture test comparable to **A-GAP-11**.

**Priority:** Medium for production scepticism; defer to Phase 2 INT3 / load tooling.

---

### New gaps identified during A8 (append as A-GAP-14+)

**A-GAP-14 — Command processor relies on Postgres vault secrets + pg_net latency**

Until `vault.create_secret` has populated `command_processor_url`,
`command_processor_anon_key`, and `command_processor_webhook_secret` (matching Edge secret
`COMMAND_PROCESSOR_WEBHOOK_SECRET`), the trigger emits a **`WARNING`** and leaves fresh
commands **`pending`** with no outbound HTTP notify. Recover still works via polling / A9
sweeper, but staging smoke tests that “INSERT then expect `processed` in <500 ms” become
timing-sensitive flakes.

**What to do:**
1. Add secrets + redeploy checklist to runbooks (`Stream A README` / onboarding doc).
2. After secrets exist, bake a MCP/poll regression: insert benign `create_game`,
   poll ≤15 s until `processed`.
3. Log/monitor pg_net `_http_response` for non-200 from the webhook URL once observability lands.

**Priority:** Medium until first production-ish environment; drops to low once secrets are standard.

---

## Priority / ordering recommendation for Phase 2 (Stream A–related items only)

1. **A-GAP-5** — small defensive `UPDATE orders` in leave/kick if still
   shipping lobby rules unchanged; cheap insurance.
2. **A-GAP-3** — privacy / RLS tightening before any production launch with
   real user emails.
3. **A-GAP-4** — concurrency join test alongside INT3 multi-tab stress
   (combine with B/C realtime tests).
4. **A-GAP-6** — product decision; code is one `IF` once decided.
5. **A-GAP-7** — unit-level classification exercised; defer full async SQL→HTTP→RPC proof to integration once vault/pg_net wired.
6. **A-GAP-1 / A-GAP-2** — optional hygiene; acceptable to close as
   "documented only" or with targeted tests if audit requires 100 % branch
   coverage.

---

*Last updated: reflects Stream A through A8 command-processor (A-GAP-8 row closed for A8,
A-GAP‑7 nuanced, new A‑GAP‑14). Prior A7 notes remain: A‑GAP‑12, A‑GAP‑13. Next infra:
vault secrets + Edge env for Upstash Redis + webhook bearer; automated async integration
polling after secrets land.*
