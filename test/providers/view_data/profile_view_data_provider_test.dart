import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_player_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/player_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/profile_view_data_provider.dart';

void main() {
  test('profileViewData maps stats + falls back to zeros on stats failure',
      () async {
    final auth = InMemoryAuthRepository();
    final players = InMemoryPlayerRepository();
    final viewer = Player(
      playerId: 'p-v',
      username: 'alice',
      createdAt: DateTime.utc(2026, 1, 1),
      email: 'a@b.com',
    );
    auth.setSessionPlayerForTest(viewer);
    players.seedRankedFinalisedGame(
      playerId: 'p-v',
      playerPnl: 10,
      topPnlInGame: 10,
    );
    players.seedRankedFinalisedGame(
      playerId: 'p-v',
      playerPnl: 5,
      topPnlInGame: 10,
    );

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        playerRepositoryProvider.overrideWithValue(players),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final data = await container.read(profileViewDataProvider.future);

    expect(data.username, 'alice');
    expect(data.email, 'a@b.com');
    expect(data.gamesPlayed, 2);
    expect(data.winRatePct, 50);
  });

  test('profileViewData throws when not signed in', () async {
    final auth = InMemoryAuthRepository();
    final players = InMemoryPlayerRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        playerRepositoryProvider.overrideWithValue(players),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    await expectLater(
      container.read(profileViewDataProvider.future),
      throwsA(isA<ProfileViewDataException>()),
    );
  });
}
