import '../../services/supabase_order_gateway.dart';
import '../models/order.dart';
import 'order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this._gateway);
  final SupabaseOrderGateway _gateway;

  @override
  Future<List<Order>> fetchOrdersForGame(String gameId) async {
    final rows = await _gateway.fetchOrderRowsForGame(gameId);
    return rows.map(Order.fromJson).toList();
  }

  @override
  Future<List<Order>> fetchPersonalOrders({
    required String gameId,
    required String playerId,
  }) async {
    final rows = await _gateway.fetchPersonalOrderRows(
      gameId: gameId,
      playerId: playerId,
    );
    return rows.map(Order.fromJson).toList();
  }

  @override
  Future<List<Order>> fetchPendingOrdersAcrossGames(String playerId) async {
    final rows = await _gateway.fetchPendingOrderRowsAcrossGames(playerId);
    return rows.map(Order.fromJson).toList();
  }

  @override
  Future<List<Order>> fetchTerminalOrdersUpdatedSinceAcrossGames(
    String playerId,
    DateTime sinceUtc,
  ) async {
    final rows = await _gateway.fetchTerminalOrderRowsUpdatedSinceAcrossGames(
      playerId,
      sinceUtc,
    );
    return rows.map(Order.fromJson).toList();
  }
}
