import '../models/order.dart';
import 'order_repository.dart';

/// Deterministic in-memory [OrderRepository] for tests. Seed via
/// [seedOrder]; fetch methods apply the same sorting rules as the real
/// impl so downstream provider tests can rely on order.
class InMemoryOrderRepository implements OrderRepository {
  final List<Order> _orders = [];

  void seedOrder(Order order) {
    _orders.add(order);
  }

  void seedOrders(Iterable<Order> orders) {
    _orders.addAll(orders);
  }

  void clear() {
    _orders.clear();
  }

  @override
  Future<List<Order>> fetchOrdersForGame(String gameId) async {
    final filtered = _orders.where((o) => o.gameId == gameId).toList();
    filtered.sort(
      (a, b) => a.orderCreatedAt.compareTo(b.orderCreatedAt),
    );
    return filtered;
  }

  @override
  Future<List<Order>> fetchPersonalOrders({
    required String gameId,
    required String playerId,
  }) async {
    final filtered = _orders
        .where((o) =>
            o.gameId == gameId && o.createdByPlayerId == playerId)
        .toList();
    filtered.sort(
      (a, b) => b.orderCreatedAt.compareTo(a.orderCreatedAt),
    );
    return filtered;
  }

  @override
  Future<List<Order>> fetchPendingOrdersAcrossGames(String playerId) async {
    final filtered = _orders
        .where((o) =>
            o.createdByPlayerId == playerId && o.status.isActive)
        .toList();
    filtered.sort(
      (a, b) => b.orderCreatedAt.compareTo(a.orderCreatedAt),
    );
    return filtered;
  }
}
