import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/models/game_session_state.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/results_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/trading_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/game_results_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/results_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/game_trading_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';

import '../../../support/stub_game.dart';

class _HarnessCurrentGame extends CurrentGame {
  _HarnessCurrentGame(this._session);
  GameSessionState _session;

  @override
  Future<GameSessionState> build(String gameId) async => _session;

  void emit(GameSessionState next) {
    _session = next;
    state = AsyncValue.data(next);
  }
}

void main() {
  testWidgets(
    'GameTradingRouteScreen navigates to results when game reaches trading_ended',
    (tester) async {
      const tid = 'transition-game';
      final auth = InMemoryAuthRepository();
      await auth.signUp(
        email: 'route-trading@test.co',
        password: 'password12',
        username: 'route_trading',
      );

      final started = GameSessionState(
        game: stubGameForRouterTests(
          gameId: tid,
          gameState: GameState.tradingStarted,
        ),
        players: const [],
      );
      final harness = _HarnessCurrentGame(started);

      final router = buildAppRouter(initialLocation: '/game/$tid/trading');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            homeViewDataProvider.overrideWith((ref) async => kMockHomeGames),
            currentGameProvider(tid).overrideWith(() => harness),
            tradingViewDataProvider(tid).overrideWith(
              (ref) => Future.value(mockTradingScenarioForGameId('g1').data),
            ),
            resultsViewDataProvider(tid).overrideWith(
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
      expect(find.byType(GameTradingScreen), findsOneWidget);

      harness.emit(
        GameSessionState(
          game: stubGameForRouterTests(
            gameId: tid,
            gameState: GameState.tradingEnded,
          ),
          players: const [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GameResultsScreen), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/game/$tid/results',
      );
    },
  );
}
