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
    updatedAt: DateTime.utc(2026, 1, 1, 10),
  );
}

void main() {
  group('mockHomeGamesFromRepositorySnapshot', () {
    test('trading_started + joined maps to active', () {
      final g = _game(id: 'g1', state: GameState.tradingStarted);
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerInitialsByGameId: {'g1': ['A', 'B']},
        viewerPlayerId: 'p-view',
      );
      expect(tiles.single.status, GameStatusBadge.active);
      expect(tiles.single.isJoined, isTrue);
      expect(tiles.single.playerInitials.length, 2);
    });

    test('created + joined + viewer is admin maps to ready', () {
      final g = _game(id: 'g1', state: GameState.created, admin: 'p-me');
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerInitialsByGameId: const {},
        viewerPlayerId: 'p-me',
      );
      expect(tiles.single.status, GameStatusBadge.ready);
    });

    test('created + joined + viewer not admin maps to joined', () {
      final g = _game(id: 'g1', state: GameState.created, admin: 'other');
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: [g],
        publicGames: const [],
        playerInitialsByGameId: const {},
        viewerPlayerId: 'p-me',
      );
      expect(tiles.single.status, GameStatusBadge.joined);
    });

    test('created + not joined maps to notJoined', () {
      final g = _game(id: 'g1', state: GameState.created);
      final tiles = mockHomeGamesFromRepositorySnapshot(
        joinedGames: const [],
        publicGames: [g],
        playerInitialsByGameId: const {},
        viewerPlayerId: 'p-me',
      );
      expect(tiles.single.status, GameStatusBadge.notJoined);
      expect(tiles.single.isJoined, isFalse);
      expect(tiles.single.isPublic, isTrue);
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
      expect(tiles[0].status, GameStatusBadge.active);
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
