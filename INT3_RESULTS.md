# INT3 — End-to-end multi-player and concurrency (Phase 2E)

Records manual outcomes for `**uncertain_envelopes_v2_phase2.plan.md**` § Phase 2E.  
Use a dev build with `**--dart-define=USE_REAL_BACKEND=true**` and the intended Supabase project unless a row says otherwise.

## How to run the app (manual tester)

From repo root:

```bash
cd uncertain-envelopes-2
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8765 \
  --dart-define=USE_REAL_BACKEND=true
```

Open `**http://127.0.0.1:8765**` (or the URL Flutter prints). Use **three separate browser profiles or containers** so sessions do not share local storage.

## Preconditions

- Three isolated sessions (three browser profiles, three devices, or three tabs with **distinct** storage / incognito per tab is **not** reliable for three persistent logins — prefer profiles).
- Three **distinct** test accounts (e.g. `you+ue3a@…`, `you+ue3b@…`, `you+ue3c@…`). Confirm email confirmation policy for your Supabase project (disable confirm for dev if needed).
- Confirm a trivial command reaches `**processed`** within a few seconds (Edge Function + vault healthy). If commands stay `**pending**`, check `**gaps-stream-a.md**` A-GAP-14 (vault secrets) and rely on sweeper latency (~10 s) before declaring failure.
- Optional: Supabase SQL editor or MCP ready to inspect `commands`, `games`, `games_players`, `executions` while reproducing issues.

## 1. Three-tab full lifecycle


| Step                              | Expected                                                                                                                                                         | Result / notes | Date |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---- |
| Tab 1: create game                | Navigates to new game lobby                                                                                                                                      |                |      |
| Tabs 2–3: join                    | Both players seated in lobby                                                                                                                                     |                |      |
| Tab 1: start                      | Lobby advances to trading for all                                                                                                                                |                |      |
| Distribute ~10 orders             | Charts, book, personal orders, logs stay consistent across tabs                                                                                                  |                |      |
| End trading (admin)               | **Trading route auto-opens `/game/:id/results`** when `game_state` reaches `trading_ended` (also on `game_finalised` / `discarded` if user is still on trading). |                |      |
| End trading → envelope → finalise | Agreed end state on all tabs; history if applicable                                                                                                              |                |      |


## 2. A-GAP-4 — last lobby slot race

**Setup:** Create a game with `**max_players`** equal to current headcount + 1 (e.g. admin + one slot left). Open two tabs as **two different users**; both attempt **join** as fast as possible (same joining code).


| Expected                                                                                                                                                  | Result / notes | Date |
| --------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ---- |
| Exactly one join succeeds; the other receives the product error (e.g. **UE002** / lobby full) with **no** duplicate `games_players` row for the same user |                |      |


**DB spot-check (optional):** `SELECT count(*) FROM games_players WHERE map_game_id = '<game_id>';` should never exceed `game_max_players`.

## 3. A-GAP-11 — simultaneous match

**Setup:** Two tabs in the **same** game, **trading** phase. Prepare crossing limit orders so two submits could race for the same resting quantity.


| Expected                                                           | Result / notes | Date |
| ------------------------------------------------------------------ | -------------- | ---- |
| No double fill; `executions` and player balances remain consistent |                |      |


## 4. A-GAP-17 — reconnect repair

**Setup:** Tab A in active trading. Chrome DevTools → **Network** → **Offline** for ~10–15 s while Tab B changes state (new order or cancel). Restore **Online** on Tab A.


| Expected                                                                                            | Result / notes | Date |
| --------------------------------------------------------------------------------------------------- | -------------- | ---- |
| After reconnect, UI catches up via `state_version` / snapshot path — no stale resting orders or PnL |                |      |


## 5. A-GAP-14 — sweeper / stuck command

**Goal:** Prove a `**claimed`** command older than the stale window is rescued (or eventually `**rejected**` after max attempts).

**Conceptual steps** (exact SQL depends on your project; use Supabase SQL editor or MCP):

1. Identify a `**commands`** row for a test game in `**claimed**` state (or insert a test command and mark `**claimed**` with `**claimed_at**` well in the past — **only on a non-production project**).
2. Wait for **pg_cron** / sweeper cycle (plan: within ~10 s of expectations).
3. Assert command moves to `**failed`** / `**processed**` / `**rejected**` per product rules and processor logs.


| Expected                                                                                     | Result / notes | Date |
| -------------------------------------------------------------------------------------------- | -------------- | ---- |
| Stuck claim recovered within documented window, or clearly `**rejected**` after max attempts |                |      |


## Bugs found during INT3


| Summary | Tracking / commit |
| ------- | ----------------- |
|         |                   |


## Sign-off

- **Tester:**
- **Date:**
- **Verdict:** ☐ PASS ☐ PASS WITH GAPS ☐ BLOCKED

