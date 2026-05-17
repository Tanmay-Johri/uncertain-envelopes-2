import '../models/order.dart';

/// Read-side surface for the `orders` table. Order *submission* lives in
/// [CommandRepository] (via `submitCreateOrder` / `submitCancelOrder`)
/// because orders are created by the command processor, not directly by
/// the client.
abstract class OrderRepository {
  /// Every order belonging to [gameId], sorted by `order_created_at` asc
  /// (FIFO) so the caller can render the book in deterministic order.
  Future<List<Order>> fetchOrdersForGame(String gameId);

  /// Orders for a single player within [gameId], sorted by
  /// `order_created_at` desc (most recent first — matches the PRD
  /// Personal Orders panel spec).
  Future<List<Order>> fetchPersonalOrders({
    required String gameId,
    required String playerId,
  });

  /// Every non-terminal order the player owns, across every game. Used by
  /// the global Pending Orders screen. Sorted by `order_created_at` desc.
  Future<List<Order>> fetchPendingOrdersAcrossGames(String playerId);

  /// Terminal orders for this player with `order_updated_at` at or after
  /// [sinceUtc] (compared in UTC). Used to show recently closed rows on the
  /// Pending Orders screen. Sorted by `order_updated_at` desc.
  Future<List<Order>> fetchTerminalOrdersUpdatedSinceAcrossGames(
    String playerId,
    DateTime sinceUtc,
  );
}
