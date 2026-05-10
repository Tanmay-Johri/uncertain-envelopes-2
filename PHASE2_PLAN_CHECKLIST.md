# Phase 2 + Phase 3 — plan checklist (evidence-backed)

**Source plan:** `~/.cursor/plans/uncertain_envelopes_v2_phase2.plan.md` (same narrative as *Uncertain Envelopes v2 — Phase 2 Integration & Phase 3 Polish*).

**Repo:** `uncertain-envelopes-2/`

**Legend**

| Status | Meaning |
|--------|---------|
| **Done** | Implemented in tree; primary tests/adapters/migrations exist where the plan asked. |
| **Partial** | Substantially there; named plan sub-clause still open (see notes). |
| **Manual** | No repo artifact proves completion — requires human / live-backend steps. |
| **Todo** | Not found or explicitly missing vs plan text. |
| **N/A** | Plan says “no provider” or out of scope for code. |

**Global gaps vs plan “iron rules”**

- **Golden / pixel contract:** Trading goldens + **INT1 mock goldens** (`int1_mock_screen_goldens_test.dart` + `test/ui/screens/goldens/{auth,home,create,lobby,results,profile,pending_orders,game_history}_*.png`). Plan §2B **mock-vs-adapter** parity per screen (beyond trading minimal harness) is still only fully exercised for **trading** + these **mock** baselines.
- **Browser MCP per slice:** Process requirement; not tracked in this file.
- **STOP before commit:** Process; actual git history may batch slices.

---

## Phase 2A — Foundation

| ID | Status | Evidence / notes |
|----|--------|-------------------|
| **2A.1** ProviderScope + Supabase init | **Done** | `lib/main.dart` → `ProviderScope` + `SupabaseBootstrapGate`; `lib/bootstrap/supabase_bootstrap.dart`; `test/bootstrap/supabase_bootstrap_test.dart`. Init runs inside gate (not blocking `runApp` first line — acceptable evolution vs plan’s literal `main` `await`). |
| **2A.2** `USE_REAL_BACKEND` + InMemory default | **Done** | `lib/providers/_environment.dart`; repository wiring + `test/providers/_environment_test.dart`. |
| **2A.3** `SupabaseRealtimeSubscriber` | **Done** | `lib/services/supabase_realtime_subscriber.dart`; `test/services/supabase_realtime_subscriber_test.dart`. |
| **2A.4** `SupabaseVersionQuery` / reader | **Done** | `lib/services/supabase_version_query.dart`; `test/services/supabase_version_query_test.dart`; wired from `game_realtime_session_provider.dart`. |
| **2A.5** A-GAP-5 leave/kick close orders | **Done** | `supabase/migrations/012_leave_kick_close_orders.sql`; `gaps-stream-a.md` log entry. |

---

## Phase 2B — INT1 (screens → providers)

| ID | Status | Evidence / notes |
|----|--------|-------------------|
| **2B recipe** Pre-slice goldens per screen | **Partial** | Mock baselines: `int1_mock_screen_goldens_test.dart` (8 screens) + trading files. **Mock vs adapter** field parity tests exist per screen where the plan required them (see `test/providers/view_data/`); trading uses `GoldenTradingMinimalHarness` for PNG parity. |
| **2B.1** Auth + redirects | **Done** (shape differs) | `AuthRouteScreen` + `authControllerProvider`; `lib/core/router/app_router_provider.dart` redirect; tests in `test/core/router/app_router_test.dart`, `test/ui/screens/auth/`. Plan’s optional `authViewDataProvider` file **not** present — functionality via controller + SnackBar errors. |
| **2B.2** Home + join by code | **Done** | `lib/providers/view_data/home_view_data_provider.dart`; `test/providers/view_data/home_view_data_provider_test.dart`; `home_screen_test.dart`. |
| **2B.3** Create game submit | **Done** | `CreateGameScreen` with `onSubmit == null` uses `ref.read(gameRepositoryProvider).createGameAndReturnGameId(...)` then `context.go(AppRoutes.gameLobby(...))` — see `lib/ui/screens/create_game/create_game_screen.dart`; router uses `const CreateGameScreen()`. |
| **2B.4** Lobby adapter + commands | **Done** | `lobby_view_data_provider.dart` + tests; `game_lobby_route_screen.dart`. |
| **2B.5** Trading adapter + commands | **Partial** | `trading_view_data_provider.dart` + `test/providers/view_data/trading_view_data_provider_test.dart`; `game_trading_route_screen.dart`. **Goldens:** `test/ui/screens/trading/game_trading_screen_golden_test.dart` — minimal fixture **mock vs adapter** same PNG (`trading_minimal_mock_vs_adapter.png`); `g1` mock baseline (`trading_dashboard_g1_mock.png`). Full `g1` cannot match adapter (chart points vs executions) — documented in test file header. |
| **2B.6** Results route host | **Done** | `results_view_data_provider.dart` + tests; `game_results_route_screen.dart`. |
| **2B.7** Profile | **Done** | `profile_view_data_provider.dart` + tests; `profile_route_screen.dart`; B-GAP-2 RPC migration `013_player_ranked_finalised_participations.sql` + `gaps-stream-b.md` apply notes. |
| **2B.8** Pending orders | **Done** | `pending_orders_view_data_provider.dart` + tests; `pending_orders_route_screen.dart`. |
| **2B.9** Game history | **Done** | `game_history_view_data_provider.dart` + tests; `game_history_route_screen.dart`. |
| **2B.10** Realtime lifecycle | **Done** (naming) | `GameRealtimeSessionScope` in `app_router.dart` shell for `/game/:id/*`; `lib/providers/game_realtime_session_provider.dart` + `game_realtime_service_provider.dart` barrel; `test/providers/game_realtime_session_provider_test.dart`. |

**`app_router.dart` production routes:** Uses `*RouteScreen` widgets — **no** `mockLobbyScenarioForGameId` / `mockTradingScenarioForGameId` in this file (meets plan “done” spirit for router wiring).

---

## Phase 2C — INT2 (real Supabase + Upstash)

| ID | Status | Evidence / notes |
|----|--------|-------------------|
| **2C.1** Auth flows (sign up, login, refresh, delete) | **Manual** | Run with `--dart-define=USE_REAL_BACKEND=true`; verify `players` / `auth.users` per plan. |
| **2C.2** Create + fetch + join | **Manual** | Same flag; command latency / vault caveats per plan. |
| **2C.3** Lobby procs | **Manual** | Two-tab realtime. |
| **2C.4** Order matching | **Manual** | Two-tab book + chart consistency. |
| **2C.5** Envelope + finalise | **Manual** | Admin + player tabs. |
| **2C.6** Offline + version repair | **Manual** | DevTools offline + reconnect. |

---

## Phase 2D — B-GAP-1 (in-queue placeholders)

| ID | Status | Evidence / notes |
|----|--------|-------------------|
| **2D** B-GAP-1 | **Done** | `CommandRepository.fetchPendingCreateOrderCommands*`; `SupabaseRealtimeSubscriber` `commands` channel; `pendingCreateOrderCommandsProvider` / merge (`lib/providers/trading_provider.dart`, `personal_orders_merge.dart`); tests in `test/providers/trading_provider_test.dart`, `active_orders_widget_test.dart`, etc. |

---

## Phase 2E — INT3 (e2e + concurrency)

| ID | Status | Evidence / notes |
|----|--------|-------------------|
| **2E** Scenarios + doc | **Partial** | `INT3_RESULTS.md` has **how-to run**, preconditions checkboxes, and per-scenario **Expected** columns — table cells still **empty** until a human runs INT3. |

---

## Phase 3 — Polish

| ID | Status | Evidence / notes |
|----|--------|-------------------|
| **POL1** Web responsive + breakpoint goldens | **Partial** | `MaxWidthCenteredLayout` in app builder; **layout goldens** at 375 / 768 / 1280: `test/ui/widgets/max_width_centered_layout_golden_test.dart` + `test/ui/widgets/goldens/max_width_layout_*.png`. Full-screen breakpoint goldens per top-level route still optional. |
| **POL2** iOS + Android pass | **Partial** | Code: `SafeArea` + scroll `keyboardDismissBehavior` + `MediaQuery.viewInsetsOf(context).bottom` padding on auth (`auth_route_screen`), home join strip (`home_screen`), create game (`create_game_screen`), new-order modal (`new_order_modal`). **Manual:** notch/home-indicator + keyboard on real devices/simulators still required for full sign-off. |
| **POL3** Error / loading / empty + retry on fetched screens | **Partial** | `FetchedErrorPanel` + invalidate on route shells (lobby, trading, results, profile, pending orders, history). `AsyncRouteLoadingBody` for loading branches. **404:** `RouteNotFoundScreen` + `Go home` (`app_router.dart`); router test taps home → `AppShell` + `HomeScreen`. **Auth:** `recoverFromSubmitError` + tests. **Home join:** inline error + `home-join-retry`. **Create game:** repository error + `create-game-submit-retry`; widget test `create_game_screen_test.dart` (POL3 group). **Shared:** `async_route_loading_body_test.dart`. Remaining sweeps: any orphan `AsyncValue.error` branches; optional widget tests for modal/home retry. |

---

## Product decisions (plan table — verify / record)

These must be **explicitly decided** and traced in `gaps-stream-*.md`, **`PRODUCT_DECISIONS.md`**, or PRD — do **not** infer from code alone:

| Topic | Plan ref |
|-------|----------|
| Mid-`trading_started` joins for ranked games | A-GAP-6 |
| Self-matching allowed? | A-GAP-10 |
| `players.email` under RLS | A-GAP-3 |
| Username uniqueness error mapping | 2B.7 / gaps-stream-c |
| Profile stats RPC vs stub | B-GAP-2 (RPC **exists** in repo; confirm product still OK) |
| Game history repo method vs stub | 2B.9 (**Done** in repo — confirm no open fork) |
| `submitCreateGame` return / navigation strategy | 2B.3 |

---

## Quick verification commands (from plan)

```bash
cd uncertain-envelopes-2
flutter analyze   # expect: No issues found!
flutter test      # expect: All tests passed!
```

After changing `@riverpod` sources:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Changelog

| Date | Change |
|------|--------|
| 2026-05-09 | Initial checklist generated from plan + repo scan. |
| 2026-05-09 | POL1: `MaxWidthCenteredLayout` + `AppLayout.maxContentWidth` (no breakpoint goldens yet). |
| 2026-05-10 | INT1 mock goldens (8 screens); POL1 max-width goldens (3 breakpoints); `INT3_RESULTS.md` expanded; `PRODUCT_DECISIONS.md` added. |
