import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/data/enums/command_type.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/models/game_session_state.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/providers/command_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/lobby_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/game_lobby_route_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_view_data.dart';

import '../../../support/home_view_data_fakes.dart';
import '../../../support/stub_game.dart';

class _HarnessCurrentGame extends CurrentGame {
  _HarnessCurrentGame(this._session);
  GameSessionState _session;

  @override
  Future<GameSessionState> build(String gameId) async => _session;
}

void main() {
  testWidgets(
    'GameLobbyRouteScreen End Game in preStart submits discard_game',
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
      final harness = _HarnessCurrentGame(session);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commandRepositoryProvider.overrideWithValue(cmds),
            lobbyViewDataProvider(gid).overrideWith((ref) => scenario),
            currentGameProvider(gid).overrideWith(() => harness),
            homeViewDataProvider.overrideWith(HomeViewDataKMockGames.new),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: GameLobbyRouteScreen(gameId: gid),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final endBtn = find.byKey(const ValueKey('game-lobby-end'));
      await tester.ensureVisible(endBtn);
      await tester.tap(endBtn);
      await tester.pumpAndSettle();

      expect(cmds.lastOfType(CommandType.discardGame), isNotNull);
      expect(cmds.lastOfType(CommandType.discardGame)!.gameId, gid);
      expect(cmds.lastOfType(CommandType.endTrading), isNull);
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
      final harness = _HarnessCurrentGame(session);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            commandRepositoryProvider.overrideWithValue(cmds),
            lobbyViewDataProvider(gid).overrideWith((ref) => scenario),
            currentGameProvider(gid).overrideWith(() => harness),
            homeViewDataProvider.overrideWith(HomeViewDataKMockGames.new),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: GameLobbyRouteScreen(gameId: gid),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final endBtn = find.byKey(const ValueKey('game-lobby-end'));
      await tester.ensureVisible(endBtn);
      await tester.tap(endBtn);
      await tester.pumpAndSettle();

      expect(cmds.lastOfType(CommandType.endTrading), isNotNull);
      expect(cmds.lastOfType(CommandType.endTrading)!.gameId, gid);
      expect(cmds.lastOfType(CommandType.discardGame), isNull);
    },
  );
}
