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
import 'package:uncertain_envelopes_2/providers/view_data/lobby_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/lobby/lobby_view_data.dart';

void main() {
  group('lobbyScenarioFromSession', () {
    test('maps created game to pre-start and trading_started to trading', () {
      final created = Game(
        gameId: 'g1',
        gameName: 'Alpha',
        gameDescription: 'Desc',
        gameCreatedAt: DateTime.utc(2026, 1, 1),
        gameSecurity: GameSecurity.private,
        isRanked: IsRanked.ranked,
        gameMaxPlayers: 8,
        joiningCode: 'ABCDE',
        endCondition: EndCondition.endless,
        gameState: GameState.created,
        adminPlayerId: 'adm1',
        stateVersion: 0,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final p1 = GamePlayer(
        gamesPlayersRowId: 'r1',
        mapGameId: 'g1',
        mapPlayerId: 'adm1',
        lobbyStatus: LobbyStatus.playing,
        joinedAt: DateTime.utc(2026, 1, 1, 12),
        isAdmin: true,
        deltaCash: 0,
        deltaEnvelopes: 0,
        pnl: 0,
      );
      final s = lobbyScenarioFromSession(
        session: GameSessionState(game: created, players: [p1]),
        viewerPlayerId: 'adm1',
        tradingSecondsRemaining: null,
      );
      expect(s.phase, GameLobbyPhase.preStart);
      expect(s.isViewerAdmin, isTrue);
      expect(s.data.gameTitle, 'Alpha');
      expect(s.data.joiningCodeRaw, 'ABCDE');
      expect(s.data.isPublic, isFalse);
      expect(s.data.isRanked, isTrue);
      expect(s.data.players.single.id, 'adm1');
      expect(s.data.players.single.isGameAdmin, isTrue);
    });

    test('timed game exposes tradingTimeRemaining when seconds provided', () {
      final timed = Game(
        gameId: 'g2',
        gameName: 'Timed',
        gameCreatedAt: DateTime.utc(2026, 1, 1),
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        joiningCode: 'XYZZY',
        endCondition: EndCondition.timed,
        totalDecidedDurationSeconds: 600,
        endTimeDecided: DateTime.utc(2026, 1, 1, 13),
        gameState: GameState.tradingStarted,
        adminPlayerId: 'a',
        stateVersion: 1,
        updatedAt: DateTime.utc(2026, 1, 1),
      );
      final s = lobbyScenarioFromSession(
        session: GameSessionState(game: timed, players: const []),
        viewerPlayerId: 'b',
        tradingSecondsRemaining: 90,
      );
      expect(s.phase, GameLobbyPhase.trading);
      expect(s.data.isTimed, isTrue);
      expect(s.data.tradingTimeRemaining, const Duration(seconds: 90));
      expect(s.isViewerAdmin, isFalse);
    });
  });

  group('lobbyViewDataProvider', () {
    test('loads scenario from seeded in-memory repositories', () async {
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
      final now = DateTime.utc(2026, 1, 1, 12);
      games.seedGame(
        Game(
          gameId: 'seed-g',
          gameName: 'Seeded',
          gameDescription: 'Hello',
          gameCreatedAt: now,
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.casual,
          gameMaxPlayers: 10,
          joiningCode: 'ZZZZZ',
          endCondition: EndCondition.endless,
          gameState: GameState.created,
          adminPlayerId: 'viewer-1',
          stateVersion: 0,
          updatedAt: now,
        ),
      );
      games.seedGamePlayer(
        GamePlayer(
          gamesPlayersRowId: 'gp1',
          mapGameId: 'seed-g',
          mapPlayerId: 'viewer-1',
          lobbyStatus: LobbyStatus.playing,
          joinedAt: now,
          isAdmin: true,
          deltaCash: 0,
          deltaEnvelopes: 0,
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
      final scenario =
          await container.read(lobbyViewDataProvider('seed-g').future);

      expect(scenario.data.gameTitle, 'Seeded');
      expect(scenario.data.joiningCodeRaw, 'ZZZZZ');
      expect(scenario.phase, GameLobbyPhase.preStart);
      expect(scenario.currentPlayerId, 'viewer-1');
      expect(scenario.isViewerAdmin, isTrue);
      expect(scenario.data.players.length, 1);
      expect(
        scenario.data.players.single.username,
        'viewer',
        reason:
            'lobby must show real `players.username`, not the UUID-derived '
            'fallback (regression: bug 3 — "Player e70b").',
      );
    });

    test(
      'falls back to lobbyDisplayUsername when profile fetch yields no row '
      '(adversarial: row present in games_players but no players row).',
      () async {
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
        final now = DateTime.utc(2026, 1, 1, 12);
        games.seedGame(
          Game(
            gameId: 'gx',
            gameName: 'X',
            gameCreatedAt: now,
            gameSecurity: GameSecurity.private,
            isRanked: IsRanked.casual,
            gameMaxPlayers: 4,
            joiningCode: 'AAAAA',
            endCondition: EndCondition.endless,
            gameState: GameState.created,
            adminPlayerId: 'viewer-1',
            stateVersion: 0,
            updatedAt: now,
          ),
        );
        games.seedGamePlayer(
          GamePlayer(
            gamesPlayersRowId: 'gpx',
            mapGameId: 'gx',
            mapPlayerId: 'orphan-99999999-aaaa-bbbb-cccc-deadbeefcafe',
            lobbyStatus: LobbyStatus.playing,
            joinedAt: now,
            isAdmin: false,
            deltaCash: 0,
            deltaEnvelopes: 0,
            pnl: 0,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            gameRepositoryProvider.overrideWithValue(games),
            playerRepositoryProvider.overrideWithValue(
              InMemoryPlayerRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authControllerProvider.future);
        final scenario =
            await container.read(lobbyViewDataProvider('gx').future);

        expect(
          scenario.data.players.single.username,
          startsWith('Player '),
        );
      },
    );

    test('router-style lobby override returns mock without hitting auth', () {
      final container = ProviderContainer(
        overrides: [
          lobbyViewDataProvider('g1').overrideWith(
            (ref) => mockLobbyScenarioForGameId('g1'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final async = container.read(lobbyViewDataProvider('g1'));
      expect(async.hasValue, isTrue);
      expect(async.requireValue.data.gameTitle, 'Forex Masters');
    });
  });
}
