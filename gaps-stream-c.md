# Stream C — known gaps and suggested fixes

This file lives in the **stream-c** worktree. After **stream-a**, **stream-b**, and **stream-c** merge into `main`, read **`gaps-stream-a.md`**, **`gaps-stream-b.md`**, and **`gaps-stream-c.md`** together for Phase 2 triage. Resolve conflicts between streams here by explicit decisions (not silent overrides).

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
| **Game cards don’t open real destinations** | `GameCard.onOpen` / home screen likely stub or debug-only. | `context.go(AppRoutes.gameLobby(id))` (or trading/results per design); pass real `id` from API model. |
| **CREATE / ORDERS shell branches** | Still `PlaceholderScreen` in `app_router.dart`. | Owned by other streams or Phase 2; align routes with merged nav spec. |
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

1. **Wire `HomeScreen` to real data and `onEnterGame`** once API contracts exist (or stub with Riverpod + fake repo behind the same interface).
2. **Navigate from `GameCard` to the correct game route** with real IDs.
3. **Triage this file + `gaps-stream-a.md` + `gaps-stream-b.md`** on `main` and turn rows into issues or PRs.
