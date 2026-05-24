import '../../data/models/execution.dart';
import '../../data/models/order.dart';
import '../../ui/screens/trading/trading_view_data.dart';

/// Builds transaction-log rows from server executions + orders (newest first).
List<TradeLogEntry> tradeLogsFromExecutions({
  required List<Execution> executions,
  required Map<String, Order> ordersById,
  required String Function(String playerId) nameForPlayer,
}) {
  final sorted = [...executions]
    ..sort((a, b) => b.executedAt.compareTo(a.executedAt));
  return [
    for (final e in sorted)
      TradeLogEntry(
        sellerName: nameForPlayer(
          ordersById[e.sellOrderId]?.createdByPlayerId ?? 'unknown',
        ),
        sellerPlayerId:
            ordersById[e.sellOrderId]?.createdByPlayerId ?? 'unknown',
        buyerName: nameForPlayer(
          ordersById[e.buyOrderId]?.createdByPlayerId ?? 'unknown',
        ),
        buyerPlayerId:
            ordersById[e.buyOrderId]?.createdByPlayerId ?? 'unknown',
        quantity: e.quantity,
        price: e.executionPrice,
        tradedAt: e.executedAt,
      ),
  ];
}
