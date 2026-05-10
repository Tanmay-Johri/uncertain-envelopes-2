# INT3 — End-to-end multi-player and concurrency (Phase 2E)

Records manual outcomes for **`uncertain_envelopes_v2_phase2.plan.md`** § Phase 2E.  
Use a dev build with **`--dart-define=USE_REAL_BACKEND=true`** and the intended Supabase project unless a row says otherwise.

## Preconditions

- [ ] Three isolated sessions (three browser profiles, three devices, or three tabs with distinct storage) and three test accounts.
- [ ] Confirm `commands.command_status` reaches `processed` within a few seconds for a trivial command (processor and vault healthy).

## 1. Three-tab full lifecycle

| Step | Expected | Result / notes | Date |
|------|-----------|----------------|------|
| Tab 1: create game | Navigates to new game lobby | | |
| Tabs 2–3: join | Both players seated in lobby | | |
| Tab 1: start | Lobby advances to trading for all | | |
| Distribute ~10 orders | Charts, book, personal orders, logs stay consistent across tabs | | |
| End trading (admin) | **Trading route auto-opens `/game/:id/results`** when `game_state` reaches `trading_ended` (also on `game_finalised` / `discarded` if user is still on trading). | | |
| End trading → envelope → finalise | Agreed end state on all tabs; history if applicable | | |

## 2. A-GAP-4 — last lobby slot race

| Expected | Result / notes | Date |
|----------|----------------|------|
| Exactly one join succeeds; the other receives the product error (e.g. **UE002** / lobby full) with no duplicate `games_players` row | | |

## 3. A-GAP-11 — simultaneous match

| Expected | Result / notes | Date |
|----------|----------------|------|
| No double fill; `executions` and balances remain consistent if two orders hit the same resting liquidity at the same time | | |

## 4. A-GAP-17 — reconnect repair

| Expected | Result / notes | Date |
|----------|----------------|------|
| After network drop during trading and reconnect, UI catches up via `state_version` / snapshot path with no stale resting orders or PnL | | |

## 5. A-GAP-14 — sweeper / stuck command

| Expected | Result / notes | Date |
|----------|----------------|------|
| Forcing a stuck `claimed` command (per ops procedure), recovery within the documented window or clear rejection after max attempts | | |

## Bugs found during INT3

| Summary | Tracking / commit |
|---------|-------------------|
| | |

## Sign-off

- **Tester:**
- **Date:**
- **Verdict:** ☐ PASS ☐ PASS WITH GAPS ☐ BLOCKED
