import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/lobby_status.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/game_player.dart';
import 'package:uncertain_envelopes_2/data/models/game_session_state.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_player_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/player_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/results_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/results_mock_data.dart';

void main() {
  group('buildGameResultsViewDataFromSession', () {
    test('maps players, envelope, and admin flag', () {
      final t = DateTime.utc(2026, 4, 1, 12);
      final game = Game(
        gameId: 'rg1',
        gameName: 'Results Game',
        gameDescription: null,
        gameCreatedAt: t,
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        joiningCode: 'ABCDE',
        endCondition: EndCondition.endless,
        gameState: GameState.tradingEnded,
        adminPlayerId: 'admin-1',
        stateVersion: 2,
        updatedAt: t,
        envelopePrice: 10.5,
      );
      final pAdmin = GamePlayer(
        gamesPlayersRowId: 'gp-a',
        mapGameId: 'rg1',
        mapPlayerId: 'admin-1',
        lobbyStatus: LobbyStatus.playing,
        joinedAt: t,
        isAdmin: true,
        deltaCash: 100,
        deltaEnvelopes: -1,
        pnl: 0,
      );
      final pOther = GamePlayer(
        gamesPlayersRowId: 'gp-b',
        mapGameId: 'rg1',
        mapPlayerId: 'other-9',
        lobbyStatus: LobbyStatus.playing,
        joinedAt: t.add(const Duration(minutes: 1)),
        isAdmin: false,
        deltaCash: -50,
        deltaEnvelopes: 2,
        pnl: 0,
      );
      final session = GameSessionState(game: game, players: [pOther, pAdmin]);
      final data = buildGameResultsViewDataFromSession(
        session: session,
        viewerPlayerId: 'admin-1',
      );
      expect(data.gameTitle, 'Results Game');
      expect(data.isViewerAdmin, isTrue);
      expect(data.envelopePriceUsd, 10.5);
      expect(data.gameEnded, isFalse);
      expect(data.highlightPlayerId, 'admin-1');
      expect(data.players.length, 2);
      expect(data.players.every((r) => r.pnl != null), isTrue);
      expect(
        data.players.map((r) => r.playerId).toList(),
        ['admin-1', 'other-9'],
      );
    });

    test('gameEnded true when finalised', () {
      final t = DateTime.utc(2026, 4, 1, 12);
      final game = Game(
        gameId: 'rg2',
        gameName: 'Done',
        gameDescription: null,
        gameCreatedAt: t,
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        joiningCode: 'ABCDE',
        endCondition: EndCondition.endless,
        gameState: GameState.gameFinalised,
        adminPlayerId: 'a',
        stateVersion: 3,
        updatedAt: t,
        envelopePrice: 5,
      );
      final session = GameSessionState(game: game, players: const []);
      final data = buildGameResultsViewDataFromSession(
        session: session,
        viewerPlayerId: 'a',
      );
      expect(data.gameEnded, isTrue);
    });
  });

  group('resultsViewDataProvider', () {
    test('loads from seeded repositories', () async {
      final commands = InMemoryCommandRepository();
      final games = InMemoryGameRepository(commandRepository: commands);
      final authRepo = InMemoryAuthRepository();
      authRepo.setSessionPlayerForTest(
        Player(
          playerId: 'viewer-1',
          username: 'viewer',
          createdAt: DateTime.utc(2026, 1, 1),
          email: 'v@test.com',
        ),
      );
      final t = DateTime.utc(2026, 5, 1, 14);
      games.seedGame(
        Game(
          gameId: 'seed-r',
          gameName: 'Seeded Results',
          gameDescription: 'x',
          gameCreatedAt: t,
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.casual,
          gameMaxPlayers: 6,
          joiningCode: 'VWXYZ',
          endCondition: EndCondition.endless,
          gameState: GameState.tradingEnded,
          adminPlayerId: 'viewer-1',
          stateVersion: 1,
          updatedAt: t,
          envelopePrice: 2,
        ),
      );
      games.seedGamePlayer(
        GamePlayer(
          gamesPlayersRowId: 'gpr1',
          mapGameId: 'seed-r',
          mapPlayerId: 'viewer-1',
          lobbyStatus: LobbyStatus.playing,
          joinedAt: t,
          isAdmin: true,
          deltaCash: 10,
          deltaEnvelopes: -3,
          pnl: 0,
        ),
      );

      final players = InMemoryPlayerRepository()
        ..seedPlayer(
          Player(
            playerId: 'viewer-1',
            username: 'viewer',
            createdAt: DateTime.utc(2026, 1, 1),
            email: 'v@test.com',
          ),
        );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          gameRepositoryProvider.overrideWithValue(games),
          playerRepositoryProvider.overrideWithValue(players),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final data = await container.read(resultsViewDataProvider('seed-r').future);

      expect(data.gameTitle, 'Seeded Results');
      expect(data.isViewerAdmin, isTrue);
      expect(data.envelopePriceUsd, 2);
      expect(
        data.players.single.displayName,
        'viewer',
        reason:
            'results screen must surface real `players.username` (bug 3 — '
            '"Player e70b" — applies to results too).',
      );
    });

    test('router-style override returns mock without hitting auth', () async {
      final container = ProviderContainer(
        overrides: [
          resultsViewDataProvider('gResults').overrideWith(
            (ref) => Future.value(mockGameResultsViewDataForGameId('gResults')),
          ),
        ],
      );
      addTearDown(container.dispose);
      final data = await container.read(resultsViewDataProvider('gResults').future);
      expect(data.isViewerAdmin, isTrue);
    });
  });
}
