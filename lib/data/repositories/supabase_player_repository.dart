import '../../services/supabase_player_gateway.dart';
import '../models/player.dart';
import 'player_repository.dart';

class SupabasePlayerRepository implements PlayerRepository {
  SupabasePlayerRepository(this._gateway);
  final SupabasePlayerGateway _gateway;

  @override
  Future<Player?> fetchProfile(String playerId) async {
    final row = await _gateway.fetchPlayerRow(playerId);
    return row == null ? null : Player.fromJson(row);
  }

  @override
  Future<Player> updateUsername({
    required String playerId,
    required String newUsername,
  }) async {
    final normalized = newUsername.trim().toLowerCase();
    try {
      final row = await _gateway.updatePlayerUsername(
        playerId: playerId,
        newUsername: normalized,
      );
      return Player.fromJson(row);
    } on GatewayUsernameInUseException {
      throw UsernameAlreadyInUseException(normalized);
    }
  }

  @override
  Future<PlayerStats> fetchPerformanceStats(String playerId) async {
    final rows =
        await _gateway.fetchRankedFinalisedGameParticipations(playerId);
    var gamesPlayed = 0;
    var wins = 0;
    for (final row in rows) {
      gamesPlayed++;
      final pnl = (row['pnl'] as num?)?.toDouble() ?? 0.0;
      final topPnl = (row['top_pnl_in_game'] as num?)?.toDouble() ?? 0.0;
      if (pnl >= topPnl) wins++;
    }
    return PlayerStats(gamesPlayed: gamesPlayed, wins: wins);
  }
}
