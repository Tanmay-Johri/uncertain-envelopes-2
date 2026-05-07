import '../models/player.dart';
import 'player_repository.dart';

/// In-memory [PlayerRepository] for tests. Seed players and per-game
/// finalised results; `fetchPerformanceStats` aggregates directly from
/// the seeded results.
class InMemoryPlayerRepository implements PlayerRepository {
  final Map<String, Player> _players = {};

  /// Finalised ranked participations keyed by player id. Each entry is
  /// (playerPnl, topPnlInThatGame).
  final Map<String, List<_Participation>> _rankedParticipations = {};

  void seedPlayer(Player player) {
    _players[player.playerId] = player;
  }

  void seedRankedFinalisedGame({
    required String playerId,
    required double playerPnl,
    required double topPnlInGame,
  }) {
    _rankedParticipations
        .putIfAbsent(playerId, () => <_Participation>[])
        .add(_Participation(playerPnl: playerPnl, topPnl: topPnlInGame));
  }

  @override
  Future<Player?> fetchProfile(String playerId) async => _players[playerId];

  @override
  Future<Player> updateUsername({
    required String playerId,
    required String newUsername,
  }) async {
    final normalized = newUsername.trim().toLowerCase();
    final existing = _players[playerId];
    if (existing == null) throw PlayerNotFoundException(playerId);
    for (final p in _players.values) {
      if (p.playerId != playerId && p.username == normalized) {
        throw UsernameAlreadyInUseException(normalized);
      }
    }
    final updated = existing.copyWith(username: normalized);
    _players[playerId] = updated;
    return updated;
  }

  @override
  Future<PlayerStats> fetchPerformanceStats(String playerId) async {
    final rows = _rankedParticipations[playerId] ?? const <_Participation>[];
    var wins = 0;
    for (final r in rows) {
      if (r.playerPnl >= r.topPnl) wins++;
    }
    return PlayerStats(gamesPlayed: rows.length, wins: wins);
  }
}

class _Participation {
  const _Participation({required this.playerPnl, required this.topPnl});
  final double playerPnl;
  final double topPnl;
}
