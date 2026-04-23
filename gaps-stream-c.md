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
| **C4d** | **Max players** stepper **1–100** (clamp, bounds on buttons). | Boundary tests: 1, 100, below 1, above 100; rapid increment. | Tap stepper edges. |
| **C4e** | **End condition** (Timed / Endless); **duration** stepper **only when Timed** (PRD-consistent bounds—align with plan; if PRD silent, use sensible default e.g. 5–180 min and document here). | Duration hidden when Endless; visible when Timed; bounds tests. | Switch end condition; confirm conditional UI. |
| **C4f** | **Submit**: `NeonButton` (or primary action) calls **`onSubmit` / mock callback** with a single DTO/map shape (no backend). | Submit emits expected payload; invalid form does not call submit. | Tap submit with valid vs invalid form. |
| **C4g** | **Sweep**: `dart analyze` project-wide if needed; `flutter test` full suite; MCP pass on `/create` at mobile-ish width; fix any regressions. | — | Final visual pass; note MCP limitations in Progress log if any. |

After **C4g**, add a short **Progress log** entry (date + commit hash). Optionally sync plan YAML todos elsewhere (`stream-c-create` → completed) if you maintain that file in-repo.

---

## Progress log (Stream C)

| Date | Slice | Commit | Notes |
|------|-------|--------|-------|
| 2026-04-23 | Game list → lobby + **C4a** | `feat(stream-c): GameCard opens lobby; C4a CreateGameScreen + /create` | `onOpenGame` + lobby route; `CreateGameScreen` + `/create`; full `flutter test`. MCP `/create`: enable-a11y click can be intercepted by `flutter-view`. |

---

## Data and backend

| Gap | Notes | Suggested direction |
|-----|--------|---------------------|
| **Home games are mock-only** | `HomeScreen` defaults to `kMockHomeGames`; no network. | Add a repository (e.g. Supabase) + Riverpod (or agreed state layer); keep `games` constructor injection for tests. |
| **`onEnterGame` not wired from router** | Shell builds `HomeScreen()` with no callback; join is a no-op in production. | Router or parent provides `onEnterGame`: validate code, call API, navigate to lobby or show error via `SnackBar` / dialog. |
| **Admin filter is client-only** | “You are admin” toggles local filter only; not persisted or server-authoritative. | Drive from profile/session claims or game payload; optional local persistence only if product agrees. |

---

## Navigation and game flow

| Gap | Notes | Suggested direction |
|-----|--------|---------------------|
| **Game cards don’t open real destinations** | **Addressed (stream-c):** `HomeScreen.onOpenGame` + router passes `go(AppRoutes.gameLobby(id))`. Still placeholder lobby UI until C5. | Replace lobby placeholder with real `GameLobbyScreen`; ensure API `id` shape matches route param. |
| **CREATE / ORDERS shell branches** | **CREATE:** `CreateGameScreen` scaffold (plan **C4a**). **ORDERS:** still `PlaceholderScreen`. | Finish C4b–f on create; build pending orders screen (C9) or Phase 2. |
| **Profile / history** | Top-level placeholders; account icon goes to `/profile`. | Merge with Stream A/B auth and profile work; single source of routes. |

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

---

## Merge checklist (Phase 2)

- [ ] Reconcile **route table** with streams A and B (auth entry, initial route, game routes).
- [ ] Single **game model** (replace `MockHomeGame` or map into shared types).
- [ ] One **gaps file triage** pass: dedupe items, assign owners, delete obsolete rows after fix.

---

## What’s next on Stream C (before or right after merge)

1. **Execute C4** using the table and **mandatory workflow** above (then C5 lobby, etc., same ritual).
2. **Wire `HomeScreen` to real data and `onEnterGame`** once API contracts exist (or stub with Riverpod + fake repo behind the same interface).
3. **Navigate from `GameCard` to the correct game route** with real IDs (partially addressed when router + `onOpenGame` land; keep row until verified).
4. **Triage this file + `gaps-stream-a.md` + `gaps-stream-b.md`** on `main` and turn rows into issues or PRs.
