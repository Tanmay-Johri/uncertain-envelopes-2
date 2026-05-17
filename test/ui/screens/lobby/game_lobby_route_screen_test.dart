import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/data/enums/command_type.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/models/game_session_state.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/providers/command_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/lobby_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/pending_orders_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/profile_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/results_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/trading_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/game_lobby_route_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_view_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/profile/profile_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/results_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';

import '../../../support/home_view_data_fakes.dart';
import '../../../support/stub_game.dart';

class _HarnessCurrentGame extends CurrentGame {
  _HarnessCurrentGame(this._session);
  GameSessionState _session;

  @override
  Future<GameSessionState> build(String gameId) async => _session;
}

class _PendingOrdersStub extends PendingOrdersViewData {
  @override
  Future<PendingOrdersScreenData> build() async {
    final items = kMockPendingOrders();
    return PendingOrdersScreenData(
      items: items,
      tradingGamesForNewOrder: tradingOrderTargetsFromPendingRows(items),
    );
  }
}

Future<GoRouter> _pumpLobbyRoute(
  WidgetTester tester, {
  required String gameId,
  required GameLobbyScenario lobbyScenario,
  required GameSessionState currentSession,
  required InMemoryCommandRepository cmds,
}) async {
  final harness = _HarnessCurrentGame(currentSession);
  final router = buildAppRouter(initialLocation: AppRoutes.gameLobby(gameId));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        commandRepositoryProvider.overrideWithValue(cmds),
        lobbyViewDataProvider(gameId).overrideWith((ref) => lobbyScenario),
        currentGameProvider(gameId).overrideWith(() => harness),
        homeViewDataProvider.overrideWith(HomeViewDataKMockGames.new),
        profileViewDataProvider.overrideWith(
          (ref) async => mockProfileViewDataDefault(),
        ),
        pendingOrdersViewDataProvider.overrideWith(_PendingOrdersStub.new),
        tradingViewDataProvider(gameId).overrideWith(
          (ref) => Future.value(mockTradingScenarioForGameId('g1').data),
        ),
        resultsViewDataProvider(gameId).overrideWith(
          (ref) => Future.value(mockGameResultsViewDataForGameId('GAME1')),
        ),
      ],
      child: MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return router;
}

void main() {
  testWidgets(
    'preStart End Game shows discard confirmation then submits and goes home',
    (tester) async {
      const gid = 'lobby-end-pre';
      final cmds = InMemoryCommandRepository();
      final scenario = mockLobbyScenarioForGameId('g2');
      expect(scenario.phase, GameLobbyPhase.preStart);
      expect(scenario.isViewerAdmin, isTrue);

      final session = GameSessionState(
        game: stubGameForRouterTests(
          gameId: gid,
          gameState: GameState.created,
        ),
        players: const [],
      );

      final router = await _pumpLobbyRoute(
        tester,
        gameId: gid,
        lobbyScenario: scenario,
        currentSession: session,
        cmds: cmds,
      );
      await tester.pumpAndSettle();

      final endBtn = find.byKey(const ValueKey('game-lobby-end'));
      await tester.ensureVisible(endBtn);
      await tester.tap(endBtn);
      await tester.pumpAndSettle();

      expect(find.text('Are you sure?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to discard this game?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(cmds.lastOfType(CommandType.discardGame), isNotNull);
      expect(cmds.lastOfType(CommandType.discardGame)!.gameId, gid);
      expect(cmds.lastOfType(CommandType.endTrading), isNull);

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'preStart End Game Back dismisses without submitting discard_game',
    (tester) async {
      const gid = 'lobby-end-pre-cancel';
      final cmds = InMemoryCommandRepository();
      final scenario = mockLobbyScenarioForGameId('g2');
      final session = GameSessionState(
        game: stubGameForRouterTests(
          gameId: gid,
          gameState: GameState.created,
        ),
        players: const [],
      );

      await _pumpLobbyRoute(
        tester,
        gameId: gid,
        lobbyScenario: scenario,
        currentSession: session,
        cmds: cmds,
      );
      await tester.pumpAndSettle();

      final endBtn = find.byKey(const ValueKey('game-lobby-end'));
      await tester.ensureVisible(endBtn);
      await tester.tap(endBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(cmds.lastOfType(CommandType.discardGame), isNull);
      expect(find.byType(GameLobbyRouteScreen), findsOneWidget);
    },
  );

  testWidgets(
    'GameLobbyRouteScreen End Game in trading submits end_trading',
    (tester) async {
      const gid = 'lobby-end-trade';
      final cmds = InMemoryCommandRepository();
      final g1 = mockLobbyScenarioForGameId('g1');
      final scenario = GameLobbyScenario(
        data: g1.data,
        phase: GameLobbyPhase.trading,
        currentPlayerId: 'p_ad',
        isViewerAdmin: true,
      );

      final session = GameSessionState(
        game: stubGameForRouterTests(
          gameId: gid,
          gameState: GameState.tradingStarted,
        ),
        players: const [],
      );

      await _pumpLobbyRoute(
        tester,
        gameId: gid,
        lobbyScenario: scenario,
        currentSession: session,
        cmds: cmds,
      );
      await tester.pumpAndSettle();

      final endBtn = find.byKey(const ValueKey('game-lobby-end'));
      await tester.ensureVisible(endBtn);
      await tester.tap(endBtn);
      await tester.pumpAndSettle();

      expect(find.text('Are you sure?'), findsNothing);
      expect(cmds.lastOfType(CommandType.endTrading), isNotNull);
      expect(cmds.lastOfType(CommandType.endTrading)!.gameId, gid);
      expect(cmds.lastOfType(CommandType.discardGame), isNull);
    },
  );
}
