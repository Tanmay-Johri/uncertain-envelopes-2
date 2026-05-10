# Stream B — Known Gaps

Gaps deliberately left open at the end of Phase 1 Stream B. Each is
non-blocking for the stream itself (all 268 tests pass) but has to be
closed before the full product flow works end-to-end. Close these during
Phase 2 (Integration) after Streams A and C have merged into `main`.

Tracked gap IDs: `B-GAP-1`, `B-GAP-2`, `B-GAP-3`.

---

## B-GAP-1 — `personalOrdersProvider` does not show "in queue" placeholders

**Where:** `lib/providers/trading_provider.dart` — `personalOrdersProvider`
(docstring already notes this gap).

**What the PRD wants (prd-uncertain-envelopes-2.md §3 create_order,
§Implementation Notes 15):**
> The `orders` row should be created only when the command processor
> actually picks up and processes that command… pending `create_order`
> commands should be shown as "in queue" orders in the UI by merging
> unprocessed commands into the personal orders view.

**Current behaviour:** The provider only reads from the `orders` table
via `ordersProvider(gameId)` filtered by `createdByPlayerId`. Between
"user taps Place Order" and "processor creates the orders row",
potentially several seconds (longer on cold processor start), the user
sees nothing in their personal orders list. Feels broken.

**Why it was skipped in B9:** Needs a second data source we have not
built yet — a read path for rows in `commands` with
`command_type = 'create_order'` and `command_status ∈
{pending, claimed, failed}` scoped to (gameId, playerId).

**What to do (in order):**

1. Extend `CommandRepository` (abstract) with:

   ```dart
   Future<List<Command>> fetchPendingCreateOrderCommands({
     required String gameId,
     required String playerId,
   });
   ```

   Implement on both `InMemoryCommandRepository` (records already
   present — filter in memory) and `SupabaseCommandRepository` (via a
   new gateway method `fetchPendingCreateOrderCommandRows`).

2. Define a small placeholder view model. Two reasonable options:
   - `PendingOrder` value class distinct from `Order`, rendered by a
     dedicated UI widget. Cleaner typing.
   - Or reuse `Order` with `orderId = 'cmd:<commandId>'` and
     `status = OrderStatus.inQueue`. The UI just needs to know the
     row is a placeholder, and the `cmd:` prefix lets cancellation
     code disable the "cancel" button (you cannot cancel an
     unprocessed command).

   Recommend the first option — typing catches misuse sooner.

3. Add a `pendingCreateCommands` notifier keyed by (gameId, playerId),
   same shape as the existing `Orders` notifier: initial fetch via the
   new repo method + delta hooks `upsert` / `remove` for the realtime
   service to drive.

4. Change `personalOrdersProvider` to **merge** the two sources:
   - Real orders first (newest first, existing logic).
   - Then pending commands that do NOT already have a corresponding
     orders row. Dedup by matching `Order.orderId` starts-with
     `'cmd:' + Command.commandId` (or an explicit `commandId` field
     on `Order` if Stream A exposes it).

5. Extend `RealtimeSubscriber` event routing to include the `commands`
   table scoped to the current player. Because commands are
   high-volume across all games, prefer a row-level realtime filter
   (`player_id = eq.<playerId>` AND `command_type = eq.create_order`)
   over a broad channel subscription.

6. Update `GameRealtimeService._handle` with a new `case 'commands'`
   branch that drives the new notifier via an added target method
   `applyPendingCommandUpsert / applyPendingCommandRemoval`. Do NOT
   reuse `applyOrderUpsert` — commands and orders have different
   lifecycles and the service must not conflate them.

**Tests to add:**
- Merge correctness when both sources have rows.
- Dedup when a command's orders row has materialised (pending command
  drops from the merged list within one realtime tick).
- Command status mapping (`pending` → "in queue", `claimed` →
  "processing", `failed` → "retrying").
- Ordering stability (newest pending command above older real orders).
- Stale pending after command reaches `rejected` (should be dropped,
  not stuck as "retrying").

---

## B-GAP-2 — `fetchPerformanceStats` depends on a Postgres RPC that Stream A has not built

**Where:** `lib/services/supabase_player_gateway.dart` —
`RealSupabasePlayerGateway.fetchRankedFinalisedGameParticipations`
calls `_client.rpc('player_ranked_finalised_participations', ...)`.

**What's missing:** A Postgres function (or view) that returns one row
per finalised-ranked participation for a given player, each row
containing at minimum `pnl` (this player's PnL) and `top_pnl_in_game`
(max PnL across all players in that game). The Dart side aggregates
those rows into `PlayerStats { gamesPlayed, wins }`.

**Why this design (not client-side aggregation):** Without the RPC we
would have to pull every `games_players` row for every finalised-
ranked game the player was ever in, just to compute a single
win-rate number. Postgres should aggregate once and return a small
result set.

**What to do:**

1. Coordinate with Stream A to add the function. Suggested shape:

   ```sql
   create or replace function player_ranked_finalised_participations(p_player_id uuid)
   returns table (map_game_id uuid, pnl numeric, top_pnl_in_game numeric)
   language sql stable as $$
     select
       gp.map_game_id,
       gp.pnl,
       (select max(gp2.pnl)
          from games_players gp2
         where gp2.map_game_id = gp.map_game_id) as top_pnl_in_game
     from games_players gp
     join games g on g.game_id = gp.map_game_id
     where gp.map_player_id = p_player_id
       and g.game_state = 'game_finalised'
       and g.is_ranked = 'ranked';
   $$;
   ```

2. Add SQL tests on the Stream A side covering:
   - Player with no finalised ranked games → empty set.
   - Win-tie semantics (multiple players with identical top PnL).
     Our Dart contract in `SupabasePlayerRepository.fetchPerformanceStats`
     is `pnl >= top_pnl_in_game` counts as a win, so ties count for
     everyone at the top.
   - Casual and unfinalised games excluded.
   - Mixed-state participation (e.g., one ranked + one casual).

3. Indexing considerations:
   - `games_players(map_player_id)` — the outer filter.
   - `games(game_state, is_ranked)` composite — the join filter.
   - Re-check the plan in A1 (stream-a's Schema unit) — they may have
     added these already.

**Alternative if A cannot add the RPC immediately:** expose two gateway
queries (participations + per-game max PnL) and do the join in Dart.
This is two round trips and duplicates the "tie counts as win" rule
across SQL and Dart. Only take this path if the RPC is blocked on
something out of our control.

---

## B-GAP-3 — Production `RealtimeSubscriber` and `SupabaseVersionReader` not implemented

**Where:**
- `lib/services/realtime_event.dart` defines the abstract
  `RealtimeSubscriber`.
- `lib/services/game_realtime_service.dart` and
  `lib/services/riverpod_realtime_target.dart` depend on it.
- Tests use a `_FakeSubscriber`.
- There is **no** `SupabaseRealtimeSubscriber` class.
- `lib/services/version_poller.dart` defines the abstract
  `SupabaseVersionReader` but has no concrete impl.

**Why they were skipped in B10:** Supabase Realtime channels need a
live `SupabaseClient` wired to the schema Stream A produces. Writing
the bridge before the schema existed would mean guessing at
channel/filter names and at how `postgres_changes` is configured per
table (A11).

**What to do, once A has merged into `main`:**

### 3a. `SupabaseRealtimeSubscriber` (new file
`lib/services/supabase_realtime_subscriber.dart`)

1. Implement `RealtimeSubscriber`. It needs to:
   - Open one Supabase channel per game (or one shared channel with
     server-side filters — check A11 for which pattern Stream A
     chose).
   - Subscribe to `postgres_changes` for each table:
     - `games`: event `UPDATE`, filter `game_id = eq.<gameId>`.
     - `games_players`: events `INSERT,UPDATE,DELETE`, filter
       `map_game_id = eq.<gameId>`.
     - `orders`: events `INSERT,UPDATE,DELETE`, filter
       `game_id = eq.<gameId>`.
     - `executions`: event `INSERT`, filter
       `executions_game_id = eq.<gameId>`.
   - Merge all four source streams into the single
     `Stream<RealtimeEvent>` the service expects.
   - Map Supabase's `PostgresChangeEvent` → our `RealtimeEvent`
     (trivial mapping, but preserve `newRow` / `oldRow` exactly —
     `GameRealtimeService` reads `oldRow['map_player_id']` and
     `oldRow['order_id']` for DELETE events).
   - Auto-reconnect on channel drops. The service already swallows
     stream errors, so reconnection-on-error belongs in the
     subscriber, not in the service.

2. Wire it in `main.dart` (Phase 2):
   - Provide real overrides for `gameRepositoryProvider`,
     `orderRepositoryProvider`, `executionRepositoryProvider`,
     `authRepositoryProvider`.
   - When a game screen opens, construct:

     ```dart
     final service = GameRealtimeService(
       gameId: gameId,
       target: RiverpodRealtimeTarget(ref: ref, gameId: gameId),
       subscriber: SupabaseRealtimeSubscriber(Supabase.instance.client),
       poller: CompositeVersionPoller(
         redis: UpstashRedisVersionReader(
           url: AppConstants.upstashRedisUrl,
           token: AppConstants.upstashRedisToken,
         ),
         supabase: SupabaseVersionReader(Supabase.instance.client),
       ),
     );
     await service.start();
     // Dispose on screen teardown.
     ```

3. Tests:
   - Integration test against a Supabase test project, tagged so CI
     can skip when no project is available.
   - Unit behaviour is already covered by the 28 cases in
     `test/services/game_realtime_service_test.dart` against the fake
     subscriber, so B10 does not need new unit tests — only the end-
     to-end wiring check.

### 3b. `SupabaseVersionReader` concrete impl

Trivial, but required for `CompositeVersionPoller` to have a fallback.
Add in `lib/services/version_poller.dart` (or a new file beside it):

```dart
class SupabaseVersionQuery implements SupabaseVersionReader {
  SupabaseVersionQuery(this._client);
  final SupabaseClient _client;

  @override
  Future<int?> readVersion(String gameId) async {
    final row = await _client
        .from('games')
        .select('state_version')
        .eq('game_id', gameId)
        .maybeSingle();
    return row?['state_version'] as int?;
  }
}
```

Tests: one happy path (row present), one missing-game case (null
return), one RLS-denied case (error surfaces / returns null, match
whatever Stream A's policies produce).

---

## Priority / ordering recommendation for Phase 2

1. **B-GAP-3 first.** Without a real subscriber, nothing updates live —
   highest user-visible impact.
2. **B-GAP-1 second.** Biggest remaining UX smell; without it, the
   trading screen looks unresponsive between order submit and
   matching.
3. **B-GAP-2 last.** Only blocks the profile screen's stats panel.
   The feature can ship with placeholder zeros while the RPC is
   authored; no user-visible breakage elsewhere.

All three are merge-safe: none require schema changes to Stream B's
existing code. They only add new files (plus one additive method on
`CommandRepository` for B-GAP-1, which cannot collide with the other
streams because those streams do not touch that file).

---

## Append-only Phase 2 log

- **2026-05-09 — B-GAP-3a (subscriber code landed, wiring deferred):**
  Added `lib/services/supabase_realtime_subscriber.dart` implementing
  `RealtimeSubscriber` with the four-table `postgres_changes` bindings
  described above, payload→`RealtimeEvent` mapping (preserving
  `newRecord`/`oldRecord`), and reconnect-on-channel-failure. Unit tests:
  `test/services/supabase_realtime_subscriber_test.dart`. Live
  integration against Supabase remains Phase 2C / INT3; the per-game
  `GameRealtimeService` lifecycle provider (plan 2B.10) is not hooked yet.

- **2026-05-09 — B-GAP-3b (reader code landed, wiring deferred):** Added
  `lib/services/supabase_version_query.dart` implementing `SupabaseVersionReader` with
  null-on-error semantics; tests `test/services/supabase_version_query_test.dart`.
  Not yet passed into `CompositeVersionPoller` from app wiring (plan 2B.10).

- **2026-05-09 — Plan 2B.10 (game realtime lifecycle wired):** Added
  `lib/providers/game_realtime_session_provider.dart` (`gameRealtimeSessionProvider`)
  wiring `GameRealtimeService` to `SupabaseRealtimeSubscriber`,
  `CompositeVersionPoller` (`UpstashRedisVersionReader` +
  `SupabaseVersionQuery(Supabase.instance.client)`), and
  `RiverpodRealtimeTarget`. Active only when `useRealBackend` is true,
  `gameId` is non-empty, and `Supabase.instance.isInitialized`. Router
  wraps `/game/:id/{lobby,trading,results}` in a `ShellRoute` whose builder
  mounts `lib/ui/widgets/game_realtime_session_scope.dart` so lobby→trading
  reuses one session. Tests: `test/providers/game_realtime_session_provider_test.dart`;
  `test/core/router/app_router_test.dart` pumps `ProviderScope` for game routes.

- **2026-05-09 — Plan 2B.1 (auth + redirect guards):** Added
  `lib/ui/screens/auth/auth_route_screen.dart` (wires `AuthScreen` to
  `authControllerProvider`, SnackBar on `AuthException`); `lib/core/router/app_router_provider.dart`
  (`appRouterProvider` + `appRouterInitialLocationProvider`) with GoRouter
  `redirect` + `refreshListenable` on auth changes; `buildAppRouter` accepts optional
  `redirect` / `refreshListenable` for tests. `UncertainEnvelopesApp` is a `ConsumerWidget`
  watching `appRouterProvider`. Tests: `test/core/router/app_router_test.dart` (auth redirect
  group), `test/widget_test.dart` (pre-seeded in-memory session).

- **2026-05-09 — Plan 2B.2 (home discovery + join by code):** Added
  `lib/providers/view_data/home_view_data_provider.dart` (`homeViewDataProvider`)
  merging `fetchJoinedGames` + `fetchPublicGames` into `List<MockHomeGame>` via
  `mockHomeGamesFromRepositorySnapshot`. `HomeScreen` uses the provider when
  `games` is null; `joinByCode` + `context.go` on Enter; loading/error UI for
  AsyncValue. Router tests override `homeViewDataProvider` with `kMockHomeGames`
  so list goldens stay stable without seeding the default repo. Tests:
  `test/providers/view_data/home_view_data_provider_test.dart`,
  `test/ui/screens/home/home_screen_test.dart` (loading/error),
  `test/core/router/app_router_test.dart` (override in `_pumpAppWith` + auth group).

- **2026-05-09 — Plan 2B.3 (create game → lobby):** Added
  `GameRepository.createGameAndReturnGameId`: `InMemoryGameRepository` inserts a
  synthetic `Game` + admin `GamePlayer` after `submitCreateGame` (joining code
  derived from the command id); `SupabaseGameRepository` polls
  `commands.command_status` / `command_game_id` via new
  `SupabaseGameGateway.fetchCommandStatusRow` (implemented on
  `RealSupabaseGameGateway`). Configurable `createGamePollInterval` /
  `createGameMaxPollAttempts` on the Supabase repo for tests. `CreateGameScreen`
  is a `ConsumerStatefulWidget`: when `onSubmit` is null it maps
  `CreateGameDraft` to repository enums, calls the repo, then
  `context.go(AppRoutes.gameLobby(gameId))`; `GameRepositoryException` → SnackBar;
  no session → SnackBar. `InMemoryAuthRepository.setSessionPlayerForTest` for
  widget tests. Tests: `test/data/repositories/game_repository_test.dart` (in-memory
  create + Supabase fake-gateway poll / reject / timeout),
  `test/ui/screens/create_game/create_game_screen_test.dart` (`ProviderScope`
  wrapper + async `onSubmit`). Verification: `flutter analyze` (0 issues),
  `flutter test` (all passed).

- **2026-05-10 — Plan 2B.4 (lobby provider + commands):** Added
  `lib/providers/view_data/lobby_view_data_provider.dart` (`lobbyViewDataProvider`):
  builds `GameLobbyScenario` from `currentGameProvider` + signed-in viewer +
  `gameSecondsRemainingProvider` + timer tick; helpers `lobbyScenarioFromSession`,
  `lobbyDisplayUsername`, `lobbyInitials`. `lib/ui/screens/lobby/game_lobby_route_screen.dart`
  watches the provider (loading/error UI), maps actions to `commandRepositoryProvider`
  submit methods, `onEnterGame` → trading route; when auth is absent (e.g. router tests
  with mock lobby overrides) command `playerId` / `adminPlayerId` fall back to
  `scenario.currentPlayerId`. `app_router.dart` lobby route uses the route screen.
  Router tests add `lobbyViewDataProvider(id)` overrides delegating to
  `mockLobbyScenarioForGameId` for stable fixtures. Tests:
  `test/providers/view_data/lobby_view_data_provider_test.dart`,
  `test/core/router/app_router_test.dart`. Verification: `flutter analyze` (0 issues),
  `flutter test` (all passed).
