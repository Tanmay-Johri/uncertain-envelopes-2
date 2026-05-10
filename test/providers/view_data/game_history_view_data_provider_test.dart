import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/lobby_status.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/game_player.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_player_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/player_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/game_history_view_data_provider.dart';

void main() {
  test('gameHistoryViewData lists finalised joined games with roster',
      () async {
    final auth = InMemoryAuthRepository();
    final commands = InMemoryCommandRepository();
    final games = InMemoryGameRepository(commandRepository: commands);
    final t = DateTime.utc(2026, 3, 1, 10);
    final end = t.add(const Duration(hours: 1));
    auth.setSessionPlayerForTest(
      Player(
        playerId: 'p1',
        username: 'u1',
        createdAt: t,
        email: 'e@test.com',
      ),
    );
    games.seedGame(
      Game(
        gameId: 'g-hist',
        gameName: 'Done Game',
        gameDescription: 'D',
        gameCreatedAt: t,
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.ranked,
        gameMaxPlayers: 4,
        joiningCode: 'ABCDE',
        endCondition: EndCondition.endless,
        gameState: GameState.gameFinalised,
        adminPlayerId: 'p1',
        stateVersion: 3,
        updatedAt: end,
        startTime: t,
        endTimeActual: end,
        envelopePrice: 5,
      ),
    );
    games.seedMembership('g-hist', 'p1');
    games.seedMembership('g-hist', 'p2');
    games.seedGamePlayer(
      GamePlayer(
        gamesPlayersRowId: 'r1',
        mapGameId: 'g-hist',
        mapPlayerId: 'p1',
        lobbyStatus: LobbyStatus.playing,
        joinedAt: t,
        isAdmin: true,
        deltaCash: 0,
        deltaEnvelopes: 2,
        pnl: 10,
      ),
    );
    games.seedGamePlayer(
      GamePlayer(
        gamesPlayersRowId: 'r2',
        mapGameId: 'g-hist',
        mapPlayerId: 'p2',
        lobbyStatus: LobbyStatus.playing,
        joinedAt: t,
        isAdmin: false,
        deltaCash: 0,
        deltaEnvelopes: -1,
        pnl: -5,
      ),
    );

    final playerRepo = InMemoryPlayerRepository()
      ..seedPlayer(
        Player(
          playerId: 'p1',
          username: 'alice_admin',
          createdAt: t,
          email: 'a@test.com',
        ),
      )
      ..seedPlayer(
        Player(
          playerId: 'p2',
          username: 'bob_peer',
          createdAt: t,
          email: 'b@test.com',
        ),
      );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        gameRepositoryProvider.overrideWithValue(games),
        playerRepositoryProvider.overrideWithValue(playerRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final entries = await container.read(gameHistoryViewDataProvider.future);

    expect(entries.single.id, 'g-hist');
    expect(entries.single.viewerPnl, 10);
    expect(entries.single.adminName, 'alice_admin');
    expect(entries.single.playerResults.first.pnl, 10);
    expect(entries.single.playerResults.first.displayName, 'alice_admin');
    expect(entries.single.playerResults.last.pnl, -5);
    expect(entries.single.playerResults.last.displayName, 'bob_peer');
  });
}
