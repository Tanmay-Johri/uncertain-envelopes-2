import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/lobby_status.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/game_player.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/widgets/status_badge.dart';

Game _game({
  required String id,
  String code = 'ABCDE',
  GameSecurity security = GameSecurity.public,
  GameState state = GameState.created,
  String admin = 'p-admin',
  DateTime? endTimeActual,
  DateTime? updatedAt,
}) {
  return Game(
    gameId: id,
    gameName: 'Game $id',
    gameCreatedAt: DateTime.utc(2026, 1, 1, 10),
    gameSecurity: security,
    isRanked: IsRanked.casual,
    gameMaxPlayers: 10,
    joiningCode: code,
    endCondition: EndCondition.endless,
    gameState: state,
    adminPlayerId: admin,
    stateVersion: 1,
    endTimeActual: endTimeActual,
    updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1, 10),
  );
}

void main() {
  group('mockHomeGamesFromRepositorySnapshot', () {
    test('trading_started + joined maps to playing', () {
      final g = _game(id: 'g1', state: GameState.tradingStarted);
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerCountByGameId: {'g1': 2},
        viewerPlayerId: 'p-view',
      );
      expect(tiles.single.status, GameStatusBadge.playing);
      expect(tiles.single.isJoined, isTrue);
      expect(tiles.single.playerCount, 2);
    });

    test('created + joined + viewer is admin maps to joined', () {
      final g = _game(id: 'g1', state: GameState.created, admin: 'p-me');
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerCountByGameId: const {},
        viewerPlayerId: 'p-me',
      );
      expect(tiles.single.status, GameStatusBadge.joined);
    });

    test('created + joined + viewer not admin maps to joined', () {
      final g = _game(id: 'g1', state: GameState.created, admin: 'other');
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerCountByGameId: const {},
        viewerPlayerId: 'p-me',
      );
      expect(tiles.single.status, GameStatusBadge.joined);
    });

    test('created + not joined maps to notJoined', () {
      final g = _game(id: 'g1', state: GameState.created);
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: const [],
        publicGames: [g],
        playerCountByGameId: const {},
        viewerPlayerId: 'p-me',
      );
      expect(tiles.single.status, GameStatusBadge.notJoined);
      expect(tiles.single.isJoined, isFalse);
      expect(tiles.single.isPublic, isTrue);
    });

    test(
        'joined trading_ended maps to playing + envelope navigation (no TTL)',
        () {
      final now = DateTime.utc(2026, 6, 1, 12);
      final end = now.subtract(const Duration(minutes: 45));
      final g = _game(
        id: 'g1',
        state: GameState.tradingEnded,
        endTimeActual: end,
        updatedAt: end,
      );
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerCountByGameId: const {},
        viewerPlayerId: 'p-me',
        nowUtc: now,
      );
      expect(tiles.single.status, GameStatusBadge.playing);
      expect(tiles.single.openEnvelopeResults, isTrue);
    });

    test(
      'joined game_finalised with stale endTimeActual but recent updatedAt still shows',
      () {
        final now = DateTime.utc(2026, 6, 1, 12);
        final tradingEnded = now.subtract(const Duration(days: 2));
        final finalisedAt = now.subtract(const Duration(minutes: 3));
        final g = _game(
          id: 'g1',
          state: GameState.gameFinalised,
          endTimeActual: tradingEnded,
          updatedAt: finalisedAt,
        );
        final tiles = mockHomeGamesFromRepositorySnapshot(
          joinedGames: [g],
          publicGames: const [],
          playerCountByGameId: const {},
          viewerPlayerId: 'p-me',
          nowUtc: now,
        );
        expect(tiles.single.status, GameStatusBadge.ended);
      },
    );

    test('joined game_finalised >10m since updatedAt is omitted from tiles', () {
      final now = DateTime.utc(2026, 6, 1, 12);
      final finalisedAt = now.subtract(const Duration(minutes: 15));
      final g = _game(
        id: 'g1',
        state: GameState.gameFinalised,
        endTimeActual: now.subtract(const Duration(days: 2)),
        updatedAt: finalisedAt,
      );
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerCountByGameId: const {},
        viewerPlayerId: 'p-me',
        nowUtc: now,
      );
      expect(tiles, isEmpty);
    });

    test('joined game_finalised within 10m of updatedAt still shows as ended', () {
      final now = DateTime.utc(2026, 6, 1, 12);
      final finalisedAt = now.subtract(const Duration(minutes: 3));
      final g = _game(
        id: 'g1',
        state: GameState.gameFinalised,
        endTimeActual: now.subtract(const Duration(hours: 1)),
        updatedAt: finalisedAt,
      );
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerCountByGameId: const {},
        viewerPlayerId: 'p-me',
        nowUtc: now,
      );
      expect(tiles.single.status, GameStatusBadge.ended);
      expect(tiles.single.openEnvelopeResults, isFalse);
    });

    test('public not joined + ended game is omitted', () {
      final now = DateTime.utc(2026, 6, 1, 12);
      final end = now.subtract(const Duration(minutes: 2));
      final g = _game(
        id: 'g1',
        state: GameState.tradingEnded,
        endTimeActual: end,
      );
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: const [],
        publicGames: [g],
        playerCountByGameId: const {},
        viewerPlayerId: 'p-me',
        nowUtc: now,
      );
      expect(tiles, isEmpty);
    });
  });

  group('homeViewDataProvider', () {
    test('returns joined then public-only tiles for signed-in user', () async {
      final commands = InMemoryCommandRepository();
      final repo = InMemoryGameRepository(commandRepository: commands);
      final authRepo = InMemoryAuthRepository();
      final me = await authRepo.signUp(
        email: 'homeview@test.co',
        password: 'password12',
        username: 'homeviewer',
      );

      final joined = _game(
        id: 'gj',
        code: 'AAAAA',
        state: GameState.tradingStarted,
        admin: me.playerId,
      );
      final publicOnly = _game(
        id: 'gp',
        code: 'BBBBB',
        state: GameState.created,
        admin: 'other-admin',
      );
      repo.seedGame(joined);
      repo.seedGame(publicOnly);
      repo.seedMembership(joined.gameId, me.playerId);
      repo.seedGamePlayer(
        GamePlayer(
          gamesPlayersRowId: 'row-1',
          mapGameId: joined.gameId,
          mapPlayerId: me.playerId,
          lobbyStatus: LobbyStatus.playing,
          joinedAt: DateTime.utc(2026, 1, 1),
          isAdmin: true,
          deltaCash: 0,
          deltaEnvelopes: 0,
          pnl: 0,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          gameRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final tiles = await container.read(homeViewDataProvider.future);

      expect(tiles.map((t) => t.id).toList(), ['gj', 'gp']);
      expect(tiles[0].isJoined, isTrue);
      expect(tiles[0].status, GameStatusBadge.playing);
      expect(tiles[1].isJoined, isFalse);
      expect(tiles[1].status, GameStatusBadge.notJoined);
    });

    test('returns empty list when not signed in', () async {
      final commands = InMemoryCommandRepository();
      final repo = InMemoryGameRepository(commandRepository: commands);
      repo.seedGame(_game(id: 'gx'));

      final container = ProviderContainer(
        overrides: [
          gameRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final tiles = await container.read(homeViewDataProvider.future);
      expect(tiles, isEmpty);
    });
  });
}
