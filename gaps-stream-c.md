# Stream C — known gaps and suggested fixes

This file lives in the **stream-c** worktree. After **stream-a**, **stream-b**, and **stream-c** merge into `main`, read **`gaps-stream-a.md`**, **`gaps-stream-b.md`**, and **`gaps-stream-c.md`** together for Phase 2 triage. Resolve conflicts between streams here by explicit decisions (not silent overrides).

---

## Stream C unit workflow (mandatory per slice)

Use this **in order** for every sub-step (e.g. C4a, C4b). Do not skip; do not commit before approval.

| Step | Action |
|------|--------|
| **1. Test** | Add or extend tests **first** when practical; otherwise in the same change before “done.” Each meaningful unit keeps its **own test file** (strict TDD). Include adversarial cases (bounds, empty, rapid taps). |
| **2. Implement** | Minimal code to satisfy tests; match existing style; no drive-by refactors. |
| **3. Analyze** | `dart analyze` on every touched library path (fix issues). |
| **4. Unit verify** | `flutter test` on the **narrowest** test file(s), then widen if the change affects shared code (e.g. router → run `app_router_test.dart`). |
| **5. Full verify** | Before any commit: `flutter test` **full suite** for this worktree. |
| **6. Browser MCP** | Run `flutter run -d web-server --web-hostname 127.0.0.1 --web-port <free port>`. In **cursor-ide-browser** MCP: `browser_navigate` to the relevant URL (e.g. `/create`). If the tree is empty, use **Enable accessibility**, wait, `browser_snapshot` again. Exercise the slice (tabs, validation, scroll). Capture screenshot or note if MCP is flaky. |
| **7. STOP — approval** | **No `git commit` until the user explicitly approves** the slice (visual + tests). |
| **8. Commit** | One **scoped** commit per slice; message references plan id (e.g. `feat(create-game): C4b form fields + validation (plan C4)`). |
| **9. Gaps** | Update **this file** in the same commit or immediately after: add newly discovered gaps, mark resolved items, or append a line under **Progress log** below. |

---

## Plan mapping — C4 Create Game screen (`stream-c-create`)

Official plan refs: YAML todos **`stream-c-create`** + **`stream-c-create-test`**; narrative **C4** in `uncertain_envelopes_v2_0644749c.plan.md`. Design ref: `design-uncertain-envelopes-2/.../admin_game_trading_dashboard_5/code.html`.

Execute slices **sequentially**. Each slice runs the **mandatory workflow** above end-to-end (including MCP, approval, commit, gaps).

| Id | Scope | Tests (minimum) | Browser MCP target |
|----|--------|-----------------|---------------------|
| **C4a** | Replace CREATE branch placeholder with `CreateGameScreen` scaffold (title/section structure); `app_router` `/create` → screen; stable `ValueKey`s for tests. | `app_router_test.dart`: CREATE branch shows new screen; new `create_game_screen_test.dart`: renders scaffold + keys. | `http://127.0.0.1:<port>/create` — shell + CREATE selected, no overflow. |
| **C4b** | Game **name** (required, max 32) + **description** (optional, max 256); inline validation messages. | `create_game_screen_test.dart`: empty name, too-long name/description, happy short values. | Fill fields, trigger validation, scroll if needed. |
| **C4c** | **Security** (Public/Private) + **Ranked** toggle; persist in local form state. | Rendering + selection toggles; at least one adversarial rapid-toggle case. | Tap each control; state visible. |
| **C4d** | **Max players** **1–128** (default **16**); ± stepper + **typed** value (floor decimals, clamp). | Bounds, rapid taps, typed cap/floor. | Tap stepper; type into center field. |
| **C4e** | **End condition** **Timed / Endless** (dropdown); **duration** **1–600** min, **typed** + stepper, **only when Timed**. | Endless hides duration; Timed shows; bounds + typed normalization. | Switch end condition; type duration. |
| **C4f** | **Submit**: `NeonButton` (or primary action) calls **`onSubmit` / mock callback** with a single DTO/map shape (no backend). | Submit emits expected payload; invalid form does not call submit. | Tap submit with valid vs invalid form. |
| **C4g** | **Sweep**: `dart analyze` project-wide if needed; `flutter test` full suite; MCP pass on `/create` at mobile-ish width; fix any regressions. | — | Final visual pass; note MCP limitations in Progress log if any. |

After **C4g**, add a short **Progress log** entry (date + commit hash). Optionally sync plan YAML todos elsewhere (`stream-c-create` → completed) if you maintain that file in-repo.

---

## Plan mapping — C5 Game Lobby (`stream-c-lobby`)

Narrative **C5** in `uncertain_envelopes_v2_0644749c.plan.md`. Design refs: `design-uncertain-envelopes-2/game_lobby_admin_with_joining_code/code.html`, `game_lobby_screen_admin_navigation_update/code.html`.

| Id | Scope | Tests (minimum) | Browser MCP target |
|----|--------|-----------------|---------------------|
| **C5** | `CountdownTimer`, `PlayerListTile`, `GameLobbyScreen`, `lobby_view_data` + `lobby_mock_data`; `/game/:id/lobby` → screen; mock scenarios **g1** (trading, joined non-admin → Enter), **g1pre** (pre-start, joined non-admin → Leave), **g2** (pre-start admin → Start + End + kicks). Non-admin **not** in `players` → **Join Game** (any phase). Admin primary: **Start** if pre-start else **Enter**, always **End** below. `NeonButtonVariant.outlineDanger` + red ink for End. | Same test files + `neon_button_test` outlineDanger / ink. | `/game/g1/lobby`, `/game/g1pre/lobby`, `/game/g2/lobby`, `/game/g4/lobby` (not seated → Join). |

**Follow-ups (not in this slice):** wire `onStartGame` / `onEndGame` / `onEnterGame` / `onJoinGame` / `onLeaveGame` / `onKickPlayer` to commands or navigation; rich empty-state when `players` is empty; replace `mockLobbyScenarioForGameId` with real `game_state` + session `currentPlayerId` after join/leave.

---

## Plan mapping — C7 Game Results (`stream-c-results`)

Narrative **C7** in `prd-uncertain-envelopes-2.md` (trading ended → admin sets `envelope_price`, end game, discarded vs finalised). Design direction: single results dashboard; admin vs non-admin.

| Id | Scope | Tests (minimum) | Browser MCP target |
|----|--------|-----------------|---------------------|
| **C7** | `GameResultsScreen`, `GameResultsMockRouteHost`, `results_view_data` + `results_mock_data`, `GameResultPlayerCard`, `AppBottomNavigationBar` (extracted from shell); `/game/:id/results` → mock host. **Admin:** editable envelope (parse 2–5 dp rules), **UPDATE FOR EVERYONE** + iteration-bounded reconcile + revert snackbar; **END GAME** + `gameEnded` read-only state (grey **UPDATE** / **GAME ENDED**). **Non-admin:** read-only hero. **PnL:** PRD `delta_cash + envelope_price * delta_envelopes` in `game_results_pnl.dart`; rows sorted descending; `null` envelope ⇒ `kUnsetUsdLine` (`$—`) on hero and PnL column. **Header:** centered title, back → `AppRoutes.gameLobby(gameId)`, no profile. Mock ids: **`gResults`** (admin), **`gResultsPlayer`** (player), **`gResultsNoPrice`** (alias). | `game_results_envelope_edit_test`, `game_results_pnl_test`, `results_view_data_test`, `game_results_screen_test`, `game_result_player_card_test`, `app_router_test` deep link. | `http://127.0.0.1:<port>/game/gResults/results` (admin), `/game/gResultsPlayer/results` (non-admin). Flutter web: wait for first frame; use **Enable accessibility** if the tree is empty; second tab for player route. |

**Follow-ups (not in this slice):** replace `GameResultsMockRouteHost` with a repository/provider that loads `GameResultsViewData` from the API; wire **trading ended** / **game_finalised** / **discarded** transitions from real `game_state`; implement `set_envelope_price` and `end_game` RPCs and drive UI only from server snapshots; optional **Browser MCP** sign-off per slice when CI cannot.

---

## Plan mapping — C9 Pending Orders (`stream-c-orders`)

Official plan refs: YAML **`stream-c-orders`** / **`stream-c-orders-test`**; narrative **C9** in `uncertain_envelopes_v2_0644749c.plan.md`. Design: `design-uncertain-envelopes-2/admin_game_trading_dashboard_4/code.html`.

| Slice | Scope | Tests | Notes |
|-------|--------|-------|--------|
| **C9a** | `pending_orders_placed_label.dart`, `pending_orders_view_data.dart`, `pending_orders_mock_data.dart` — sort newest-first, side filter **All / Buy / Sell**, `PersonalOrder` reuse. | `pending_orders_placed_label_test.dart`, `pending_orders_view_data_test.dart` | |
| **C9b** | `PendingOrderCard` — collapsed title/qty/price/Buy·Sell; expanded description, Order ID, `Placed:` via injectable `now`, cancel + `ConfirmationDialog` when cancellable. | `pending_order_card_test.dart` | Market headline price `—`. |
| **C9c** | `PendingOrdersScreen` under **`AppShell`** `/orders`; filter bottom sheet; empty vs filter-empty copy; optional `onCancelOrder` stub. | `pending_orders_screen_test.dart` | |
| **C9d** | `app_router` ORDERS branch → screen; `app_router_test` ORDERS navigation. | `app_router_test.dart` | |
| **C9e** | `dart analyze` touched paths; full `flutter test`; gaps doc. MCP: `/orders` when practical. | — | |

---

## Progress log (Stream C)

| Date | Slice | Commit | Notes |
|------|-------|--------|-------|
| 2026-04-23 | Game list → lobby + **C4a** | `feat(stream-c): GameCard opens lobby; C4a CreateGameScreen + /create` | `onOpenGame` + lobby route; `CreateGameScreen` + `/create`; full `flutter test`. MCP `/create`: enable-a11y click can be intercepted by `flutter-view`. |
| 2026-04-23 | **C4b** name + description | `feat(create-game): C4b name and description validation` | Trimmed name required, max 32; description optional, max 256. No `maxLength` on fields so paste/long input hits validator (C4f may add live counters). |
| 2026-04-23 | **C4c** security + ranked | `feat(create-game): C4c security SegmentedButton and ranked switch` | `CreateGameSecurity` enum; `SegmentedButton` Public/Private (M3; avoids deprecated `RadioListTile.groupValue`); `SwitchListTile` ranked. Tests: defaults, selection, ranked + rapid toggles. |
| 2026-04-23 | **C4d** max players | `feat(create-game): C4d max players stepper` | `CreateGamePlayerLimits` 1–100, default 8; `IconButton` ± row; tests use `ensureVisible` (stepper below fold). |
| 2026-04-23 | **Create game** polish + shell | `feat(create-game): design parity, editable limits, shell header fix` | HTML ref layout (security tiles, Timed/Endless dropdown, boxed steppers, `NeonButton`); description placeholder; duration **1–600** + max players **1–128** (default **16**) with commit-on-blur typing; primary section labels; `AppShell` body below frosted header (no blurred ghost text); `AppConstants.maxMaxPlayers` 128; `flutter test` full suite green. |
| 2026-04-23 | **C4f** submit + DTO + **C4g** sweep | `feat(create-game): C4f CreateGameDraft onSubmit + C4g verify` | `CreateGameDraft` + `toJson()`; `CreateGameScreen(onSubmit?)` wires `NeonButton` to validate, commit blur fields, then callback; router keeps `const CreateGameScreen()`. Tests: invalid → no callback; valid trimmed payload; Endless → `durationMinutes` null in JSON; rapid double submit → two calls. C4f widget tests use a **tall surface** (`physicalSize` 2000px) + `ensureVisible` so submit is hit-testable (default ~600px viewport put the button under absorbing/offstage layers). C4g: full `flutter test` green; `dart analyze` still reports **8 info** issues elsewhere (`app_router` unnecessary underscores, `main` depend_on_referenced_packages, `auth_tab_switcher_test` / `confirmation_dialog_test` lints) — not introduced here. Browser MCP `/create` not re-run in this session; use `flutter run -d web-server` + snapshot when needed. |
| 2026-04-23 | **C5** Game Lobby (mock) | `feat(lobby): C5 game lobby mock UI, routes, and tests` | `GameLobbyScreen`, `CountdownTimer`, `PlayerListTile`, `lobby_view_data`, `lobby_mock_data`; router `/game/:id/lobby` with no-op callbacks for all actions. Mocks: **g1** trading, **g1pre** non-admin pre-start (same roster as g1), **g2** admin pre-start; other ids from `kMockHomeGames` default to **trading** + `currentPlayerId: 'viewer'` (e.g. **g4** → Join Game). Joined vs not: `lobbyViewerIsInPlayerList`. `CountdownTimer`: **1s `Timer.periodic`** (not per-frame ticker) for `pumpAndSettle`. `NeonButton` **outlineDanger** + red splash/highlight for End. **Browser MCP:** Flutter web often needs **Enable accessibility** before the tree fills; blank white can appear briefly; use a fresh `flutter run` port if bundle stale. Full `flutter test` green before commit. |
| 2026-04-23 | **C6** PnL calculator (trading) | `feat(trading): C6 PnL calculator with dynamic envelope bounds` | `projectedPnl`, `envelopeSliderBoundsForCenter` / `valueFitsInBounds`, input parsing, `PnlCalculator` (ExpansionTile, slider + typed + reset, dynamic bounds), `formatProjectedPnl`, `GameTradingScreen` order **stats → PnL → chart → order book**; full `flutter test` green, `dart analyze` unchanged warnings elsewhere. **Bounds (C6):** raw = ±50% of center; for **v < 1** and **1 ≤ v < 10** use a common decimal scale [p] (0…8) so both raws match after `round(·×10^p)/10^p`, then same min-digit + step grid, **clamp** to [0,1] or [0,10], then “≈1” rules. For **v ≥ 10** use truncated int raws. **Browser MCP** `/game/g1/trading` not run. |
| 2026-04-23 | **C7** Game Results (mock envelope + leaderboard) | `736c473` — `feat(results): C7 game results screen with envelope admin flow` | Results route + mock host; admin UPDATE / reconcile / END GAME + `gameEnded` UI; PRD PnL in core + sorted rows; `$—` unset line (`kUnsetUsdLine`); blurred empty draft does not mirror committed price until UPDATE; caret collapsed on focus (`TextSelection.collapsed`). **Gaps:** no real backend; trading screen does not auto-route here on phase change; MCP canvas sometimes blank until delay or accessibility. Full `flutter test` green before commit. |
| 2026-05-02 | **C8** Profile (`/profile`) | — | `ProfileScreen`: while editing username, **close** always visible (revert); **check** always visible (confirm, grey until dirty or taken); inline **`Username taken`**. Router mocks rename (`taken` only for literal username `taken`); **`onSignOut`** empty closure for NeonButton parity; **`/history`** still placeholder. **`flutter run -d web-server`:** prefer **`--release`** if debug waits forever on DDS. Full `flutter test` green before commit. |
| 2026-05-03 | **C9** Pending orders (`/orders`) | `feat(orders): C9 PendingOrdersScreen + PendingOrderCard` | `PendingOrdersScreen` / **`PendingOrderCard`** / **`kMockPendingOrders`** from HTML ref **`admin_game_trading_dashboard_4`**; side-filter sheet (**All \| Buy \| Sell**); **`pendingOrderPlacedLabel`**; **`onCancelOrder`** optional (router omits — no persistence). **`flutter test`** 493 passes; MCP `/orders` not run here. Phase 2: repository + ack path like **`GameTradingScreen`**. |

---

## Worktree / merge remarks — C5 (stream-c)

- **Branch:** `stream-c`. No other worktrees touched in this commit; when merging to `main`, reconcile with **stream-a** / **stream-b** using the **Merge checklist (Phase 2)** below (routes, auth entry, game model).
- **Router:** Lobby is a **top-level** `GoRoute` (outside shell); **HomeScreen** `onOpenGame` navigates with `go`. Merge conflicts most likely in `app_router.dart` if other streams add sibling routes—preserve shell vs top-level distinction.
- **Mock seam:** `mockLobbyScenarioForGameId` is **temporary**; deleting or renaming game ids (`g1pre`, etc.) will break tests and manual QA URLs until replaced by API-driven scenarios.
- **Analyze:** Project may still report **info**-level lints unrelated to C5 (e.g. `app_router` unnecessary underscores, `visible_for_testing` on `formatCountdownMmSs` consumer). Triage on merge; not blocking this slice.

---

## Data and backend

| Gap | Notes | Suggested direction |
|-----|--------|---------------------|
| **Home games are mock-only** | `HomeScreen` defaults to `kMockHomeGames`; no network. | Add a repository (e.g. Supabase) + Riverpod (or agreed state layer); keep `games` constructor injection for tests. |
| **`onEnterGame` not wired from router** | Shell builds `HomeScreen()` with no callback; join is a no-op in production. | Router or parent provides `onEnterGame`: validate code, call API, navigate to lobby or show error via `SnackBar` / dialog. |
| **Admin filter is client-only** | “You are admin” toggles local filter only; not persisted or server-authoritative. | Drive from profile/session claims or game payload; optional local persistence only if product agrees. |
| **Active orders: `Cancelling` vs backend** | Stream-c **mock** uses `defaultSubmitCancelOrderCommandAck` (short delay) + a worker delay before local `cancelled`; **10s** `AppConstants.cancelOrderCommandAckTimeout` on command-row ack via `.timeout`; on timeout/error the UI reverts from **Cancelling** and shows **“Could not create cancellation request”** (`kCancelOrderCommandAckFailedMessage`). Reconciles orders from `GameTradingViewData`; clears pending on terminal status (`personalOrderClearsCancellationPending`). | **Production:** optimistic **Cancelling** on confirm; `submitCancelOrderCommand` completes only when the **`cancel_order` command row** is ack’d; if ack does not arrive within **10s** (or RPC errors), revert + banner; after ack, stay **Cancelling** until the **orders** snapshot shows **`cancelled`**. Replace mock worker timer with realtime/polling. Inject `GameTradingScreen.submitCancelOrderCommand` in tests (e.g. non-completing `Future` for timeout coverage). |
| **`GameResultsMockRouteHost` is mock-only** | Envelope commits, polls, `gameEnded`, and PnLs are simulated in-widget state—not server truth. | Add `GameResultsRepository` (or Supabase/REST) returning `GameResultsViewData` + streams; **admin** calls `set_envelope_price` / `end_game`; **reconcile** uses real poll or subscription; delete or shrink mock host behind `kDebugMode` / tests only. |
| **Final PnL only as server snapshot** | UI applies PRD formula in `withEnvelopeUsd` for mock coherence; production must trust backend rows (cheating resistance). | Ensure API returns per-player **`pnl`** (or deltas + authoritative `envelope_price`) and Flutter **displays** only—no recomputing leaderboard PnL from deltas in release unless product explicitly dual-verifies. |
| **`envelope_price` typing / optional game rows** | Create-game and lobby do not surface results-phase rules; discarded vs finalised is UI-only confirmation today. | Align with PRD § game lifecycle; persist `discarded` / `game_finalised` on server; gate routes (e.g. block trading after end). |
| **`ProfileScreen` reads mock `ProfileViewData` only** | Router injects **`mockProfileViewDataDefault()`**; not tied to Supabase **`auth`** or profiles table. | Add repository / Riverpod provider; map session user → **`ProfileViewData`**; optimistic updates after successful rename. |
| **Username rename is simulated** | **`onUsernameCommit`** in **`app_router`**: succeeds unless lowercase name is **`taken`**. | Call real **update username** mutation; translate unique-violation / API errors → **`ProfileUsernameSubmitResult.taken`** + localized copy. |
| **Sign-out and delete-account are stubs** | **`onSignOut: () {}`** and **`onDeleteAccount: () {}`** in **`app_router`** so **`NeonButton` / confirmation** always have callbacks; confirmations still perform no persistence in Stream C. | **`onSignOut`:** revoke session + **`context.go(AppRoutes.auth)`**. **`onDeleteAccount`:** account deletion RPC + clear local session + navigate. |
| **Game History route** | **`/history`** **`PlaceholderScreen`**. | Build history list screen (dedicated slice) or defer to Phase 2. |

---

## Navigation and game flow

| Gap | Notes | Suggested direction |
|-----|--------|---------------------|
| **Game cards don’t open real destinations** | **Addressed (stream-c):** `HomeScreen.onOpenGame` + router → `GameLobbyScreen` (mock data by id). | Phase 2: replace mocks with `GameRepository` snapshot; ensure API `id` shape matches route param. |
| **CREATE / ORDERS shell branches** | **CREATE:** `CreateGameScreen`; **ORDERS:** **`PendingOrdersScreen`** (**C9** mock). | Wire **`onCancelOrder`** to commands + realtime; **`OrderRepository.fetchPendingOrdersAcrossGames`**. |
| **Profile (`/profile`)** | **C8 complete (mock):** same as Stream C UX spec; **`VERIFIED`** micro-tag when **`emailVerified`**; delete flow uses **`ConfirmationDialog`** → **`onDeleteAccount`**. Router: mock rename (`taken` literal), **`onSignOut`** / **`onDeleteAccount`** no-ops for now. **`/history`** still placeholder. | Load profile from Supabase/session; real rename + uniqueness errors; **`onSignOut`** + **`onDeleteAccount`** wired to APIs; ship **History** UI; reconcile with Streams A/B auth. |
| **Trading → Results navigation** | User can deep-link `/game/:id/results`; **no** automatic `go` from `GameTradingScreen` when phase becomes *trading ended*. | Subscribe to game phase (WS/poll); when server reports trading ended, navigate or show CTA to results; keep deep link as fallback. |
| **Results bottom nav** | Same Home / Create / Orders shell destinations; **no** “current game” persistence from results. | Optional: pass `gameId` query or restore last game from session when returning from shell. |

---

## UI / UX (joining code)

| Gap | Notes | Suggested direction |
|-----|--------|---------------------|
| **Caret vertical alignment is tuned, not proven** | `CodeInput` uses `TextAlignVertical(y: -0.07)`, strut, and tall `cursorHeight` for optical center; web DOM overlay can still disagree slightly. | Re-verify on iOS, Android, and web (HTML + CanvasKit if both supported); adjust single constant or add `Theme`/`MediaQuery` branch if needed. |
| **`_enterGameButtonHeight` vs `NeonButton`** | `CodeInput` caps square size using a duplicated `48` that must stay in sync with `NeonButton` default height. | Export a shared layout constant from one module or read from `NeonButton` API if exposed. |
| **Accessibility** | Code cells and cards may lack rich `Semantics` / labels for screen readers. | Add `Semantics` for each cell (e.g. “Joining code digit 1 of 5”) and for tappable cards. |

---

## Web / tooling (non-product but recurring)

| Gap | Notes | Suggested direction |
|-----|--------|---------------------|
| **Browser MCP / embedded browser** | Flutter web may show blank until “Enable accessibility” or similar; snapshots can lag. | Document in contributor README; use full browser for visual sign-off when MCP is flaky. |
| **Text input on web** | Framework uses DOM-backed editing; alignment and selection issues have a long issue history upstream. | Prefer designs that decouple **chrome** (`DecoratedBox`) from **editable** (already done for `CodeInput`); re-test after Flutter upgrades. |

---

## Testing

| Gap | Notes | Suggested direction |
|-----|--------|---------------------|
| **No golden / integration tests for home web** | Widget tests cover logic; pixel-perfect caret/layout not locked. | Optional goldens on CI for `CodeInput` + home strip; or manual checklist per release on web. |
| **E2E join flow** | No end-to-end test from code entry through navigation. | Add when API exists (e.g. integration_test + mock server). |
| **Create form length limits** | C4b uses validators only (no `maxLength`), so users can type past limits until submit/validate. | Add `maxLength` + `buildCounter: null` or a character chip when product wants hard caps in the field. |

---

## Merge checklist (Phase 2)

- [ ] Reconcile **route table** with streams A and B (auth entry, initial route, game routes).
- [ ] Single **game model** (replace `MockHomeGame` or map into shared types).
- [ ] One **gaps file triage** pass: dedupe items, assign owners, delete obsolete rows after fix.

---

## What’s next on Stream C (before or right after merge)

1. **C7 → production seam:** implement `GameResultsRepository` + authz (admin vs player), `set_envelope_price` and `end_game` commands, and replace `GameResultsMockRouteHost` with a provider that maps API DTOs → `GameResultsViewData` (keep mock for tests / dev flag).
2. **Phase-driven navigation:** when `game_state` enters *trading ended*, route from `GameTradingScreen` (or show explicit “View results”) to `/game/:id/results`; handle *discarded* / *game_finalised* redirects if the user deep-links stale URLs.
3. **Lobby / menu integration:** wire **End game** on trading and lobby to the same backend semantics as results **END GAME**; ensure a single source of truth for “game ended” so admin cannot double-submit.
4. **history / polish:** **`/history`** still placeholder (**C10**); reconcile with Stream A/B auth entry and session.
5. **Browser MCP hygiene:** document Flutter web **Enable accessibility** + ~5–8s first paint for results URLs; add a short **contributor** note if not already in README.
6. **Merge prep:** triage **this file** + `gaps-stream-a.md` + `gaps-stream-b.md` on `main`; resolve route table and game model conflicts; turn open rows into issues with owners.
