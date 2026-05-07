import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_player_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/player_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/supabase_player_repository.dart';
import 'package:uncertain_envelopes_2/services/supabase_player_gateway.dart';

Player _player({
  String id = 'p-1',
  String username = 'alice',
  String email = 'a@x.com',
}) {
  return Player(
    playerId: id,
    username: username,
    email: email,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('PlayerStats', () {
    test('winRate handles zero games without divide-by-zero', () {
      const s = PlayerStats(gamesPlayed: 0, wins: 0);
      expect(s.winRate, 0);
    });
    test('winRate computes wins / gamesPlayed', () {
      const s = PlayerStats(gamesPlayed: 5, wins: 2);
      expect(s.winRate, closeTo(0.4, 1e-9));
    });
    test('cannot construct with wins > gamesPlayed', () {
      expect(
        () => PlayerStats(gamesPlayed: 1, wins: 2),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('InMemoryPlayerRepository', () {
    late InMemoryPlayerRepository repo;
    setUp(() => repo = InMemoryPlayerRepository());

    test('fetchProfile returns null when absent', () async {
      expect(await repo.fetchProfile('nope'), isNull);
    });

    test('fetchProfile returns seeded player', () async {
      repo.seedPlayer(_player());
      expect((await repo.fetchProfile('p-1'))?.username, 'alice');
    });

    test('updateUsername lowercases and persists', () async {
      repo.seedPlayer(_player());
      final updated = await repo.updateUsername(
        playerId: 'p-1',
        newUsername: 'AliceNEW',
      );
      expect(updated.username, 'alicenew');
      expect((await repo.fetchProfile('p-1'))?.username, 'alicenew');
    });

    test('updateUsername throws PlayerNotFoundException for unknown id',
        () async {
      expect(
        () => repo.updateUsername(playerId: 'nope', newUsername: 'x'),
        throwsA(isA<PlayerNotFoundException>()),
      );
    });

    test(
        'updateUsername rejects duplicate (case-insensitive)'
        ' by raising UsernameAlreadyInUseException', () async {
      repo.seedPlayer(_player(id: 'p-1', username: 'alice'));
      repo.seedPlayer(_player(id: 'p-2', username: 'bob'));
      expect(
        () => repo.updateUsername(playerId: 'p-2', newUsername: 'ALICE'),
        throwsA(isA<UsernameAlreadyInUseException>()),
      );
    });

    test('updateUsername allows same-player identity update', () async {
      repo.seedPlayer(_player(id: 'p-1', username: 'alice'));
      final updated = await repo.updateUsername(
        playerId: 'p-1',
        newUsername: 'Alice',
      );
      expect(updated.username, 'alice');
    });

    test('fetchPerformanceStats returns zero stats when no games', () async {
      repo.seedPlayer(_player());
      final stats = await repo.fetchPerformanceStats('p-1');
      expect(stats.gamesPlayed, 0);
      expect(stats.wins, 0);
      expect(stats.winRate, 0);
    });

    test(
        'fetchPerformanceStats counts games and wins (ties count as wins)',
        () async {
      repo.seedPlayer(_player());
      repo.seedRankedFinalisedGame(
        playerId: 'p-1',
        playerPnl: 100,
        topPnlInGame: 100,
      ); // win (tie)
      repo.seedRankedFinalisedGame(
        playerId: 'p-1',
        playerPnl: 50,
        topPnlInGame: 120,
      ); // loss
      repo.seedRankedFinalisedGame(
        playerId: 'p-1',
        playerPnl: 200,
        topPnlInGame: 200,
      ); // win
      final stats = await repo.fetchPerformanceStats('p-1');
      expect(stats.gamesPlayed, 3);
      expect(stats.wins, 2);
      expect(stats.winRate, closeTo(2 / 3, 1e-9));
    });
  });

  group('SupabasePlayerRepository (fake gateway)', () {
    late _FakePlayerGateway gateway;
    late SupabasePlayerRepository repo;

    setUp(() {
      gateway = _FakePlayerGateway();
      repo = SupabasePlayerRepository(gateway);
    });

    test('fetchProfile decodes gateway row', () async {
      gateway.rows['p-1'] = _player().toJson();
      expect((await repo.fetchProfile('p-1'))?.username, 'alice');
    });

    test('fetchProfile returns null on missing row', () async {
      expect(await repo.fetchProfile('nope'), isNull);
    });

    test('updateUsername normalises to lowercase before calling gateway',
        () async {
      gateway.rows['p-1'] = _player().toJson();
      await repo.updateUsername(playerId: 'p-1', newUsername: '  BOB  ');
      expect(gateway.lastUpdate?['username'], 'bob');
    });

    test('updateUsername translates gateway username-in-use exception',
        () async {
      gateway.throwOnUpdate = const GatewayUsernameInUseException();
      expect(
        () => repo.updateUsername(playerId: 'p-1', newUsername: 'dupe'),
        throwsA(isA<UsernameAlreadyInUseException>()),
      );
    });

    test('fetchPerformanceStats aggregates from gateway rows', () async {
      gateway.rankedRows = [
        {'pnl': 100.0, 'top_pnl_in_game': 100.0, 'map_game_id': 'g1'},
        {'pnl': 40.0, 'top_pnl_in_game': 90.0, 'map_game_id': 'g2'},
        {'pnl': 150.0, 'top_pnl_in_game': 150.0, 'map_game_id': 'g3'},
      ];
      final stats = await repo.fetchPerformanceStats('p-1');
      expect(stats.gamesPlayed, 3);
      expect(stats.wins, 2);
    });

    test('fetchPerformanceStats handles empty rows', () async {
      gateway.rankedRows = [];
      final stats = await repo.fetchPerformanceStats('p-1');
      expect(stats, const PlayerStats(gamesPlayed: 0, wins: 0));
    });
  });
}

class _FakePlayerGateway implements SupabasePlayerGateway {
  final Map<String, Map<String, dynamic>> rows = {};
  List<Map<String, dynamic>> rankedRows = [];
  Map<String, dynamic>? lastUpdate;
  Object? throwOnUpdate;

  @override
  Future<Map<String, dynamic>?> fetchPlayerRow(String playerId) async =>
      rows[playerId];

  @override
  Future<Map<String, dynamic>> updatePlayerUsername({
    required String playerId,
    required String newUsername,
  }) async {
    if (throwOnUpdate != null) throw throwOnUpdate!;
    final existing = rows[playerId] ?? {};
    lastUpdate = {'player_id': playerId, 'username': newUsername};
    existing['username'] = newUsername;
    rows[playerId] = existing;
    return existing;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRankedFinalisedGameParticipations(
    String playerId,
  ) async =>
      rankedRows;
}
