import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Narrow seam for the `orders` reads that [SupabaseOrderRepository] needs.
abstract class SupabaseOrderGateway {
  Future<List<Map<String, dynamic>>> fetchOrderRowsForGame(String gameId);
  Future<List<Map<String, dynamic>>> fetchPersonalOrderRows({
    required String gameId,
    required String playerId,
  });
  Future<List<Map<String, dynamic>>> fetchPendingOrderRowsAcrossGames(
    String playerId,
  );
}

class RealSupabaseOrderGateway implements SupabaseOrderGateway {
  RealSupabaseOrderGateway(this._client);

  final sb.SupabaseClient _client;

  /// The three non-terminal statuses per PRD §orders.status. Used for
  /// the "pending across games" query.
  static const _nonTerminalStatuses = <String>[
    'in_queue',
    'being_processed',
    'order_resting',
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchOrderRowsForGame(
    String gameId,
  ) async {
    final rows = await _client
        .from('orders')
        .select()
        .eq('game_id', gameId)
        .order('order_created_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPersonalOrderRows({
    required String gameId,
    required String playerId,
  }) async {
    final rows = await _client
        .from('orders')
        .select()
        .eq('game_id', gameId)
        .eq('created_by_player_id', playerId)
        .order('order_created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPendingOrderRowsAcrossGames(
    String playerId,
  ) async {
    final rows = await _client
        .from('orders')
        .select()
        .eq('created_by_player_id', playerId)
        .inFilter('status', _nonTerminalStatuses)
        .order('order_created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
