import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Narrow seam for `players` + ranked-game-stat reads/writes.
abstract class SupabasePlayerGateway {
  Future<Map<String, dynamic>?> fetchPlayerRow(String playerId);

  /// Bulk read of `players` rows for [playerIds]. Empty list → empty result.
  /// Caller filters / maps; this gateway does not deserialise.
  Future<List<Map<String, dynamic>>> fetchPlayerRowsByIds(
    List<String> playerIds,
  );

  /// Updates the username field. Throws
  /// [GatewayUsernameInUseException] if the uniqueness constraint fires.
  Future<Map<String, dynamic>> updatePlayerUsername({
    required String playerId,
    required String newUsername,
  });

  /// Returns raw `games_players` rows across all finalised ranked games
  /// for the player, plus the admin / finalisation status they need for
  /// win calculation. Each row must carry:
  ///   - `pnl` (double)
  ///   - `map_game_id` (string)
  ///   - `top_pnl_in_game` (double) — present on RPC rows; wins use `pnl > 0`
  Future<List<Map<String, dynamic>>> fetchRankedFinalisedGameParticipations(
    String playerId,
  );
}

class GatewayUsernameInUseException implements Exception {
  const GatewayUsernameInUseException();
  @override
  String toString() => 'GatewayUsernameInUseException';
}

class RealSupabasePlayerGateway implements SupabasePlayerGateway {
  RealSupabasePlayerGateway(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchPlayerRow(String playerId) async {
    final row = await _client
        .from('players')
        .select()
        .eq('player_id', playerId)
        .maybeSingle();
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPlayerRowsByIds(
    List<String> playerIds,
  ) async {
    if (playerIds.isEmpty) return const [];
    final rows = await _client
        .from('players')
        .select()
        .inFilter('player_id', playerIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<Map<String, dynamic>> updatePlayerUsername({
    required String playerId,
    required String newUsername,
  }) async {
    try {
      final row = await _client
          .from('players')
          .update({'username': newUsername})
          .eq('player_id', playerId)
          .select()
          .single();
      return row;
    } on sb.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const GatewayUsernameInUseException();
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRankedFinalisedGameParticipations(
    String playerId,
  ) async {
    // This assumes a Postgres view or RPC exposes the per-game top pnl.
    // Real wiring is set up by Stream A; this call stays thin.
    final rows = await _client
        .rpc<List<dynamic>>(
          'player_ranked_finalised_participations',
          params: {'p_player_id': playerId},
        );
    return rows
        .cast<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
  }
}
