import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/trade_logs_from_executions.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/models/execution.dart';
import 'package:uncertain_envelopes_2/data/models/order.dart';

Order _order(String id, String playerId) {
  return Order(
    orderId: id,
    createdByPlayerId: playerId,
    gameId: 'g1',
    type: OrderType.limitSell,
    quantityInitial: 1,
    quantityCurrent: 0,
    pricePerStock: 100,
    status: OrderStatus.orderClosed,
    orderCreatedAt: DateTime.utc(2024, 1, 1),
    orderUpdatedAt: DateTime.utc(2024, 1, 1),
  );
}

Execution _execution({
  required String id,
  required String sellOrderId,
  required String buyOrderId,
  required DateTime at,
  double price = 100,
}) {
  return Execution(
    executionsId: id,
    executionsGameId: 'g1',
    sellOrderId: sellOrderId,
    buyOrderId: buyOrderId,
    quantity: 2,
    executionPrice: price,
    executedAt: at,
  );
}

void main() {
  group('tradeLogsFromExecutions', () {
    test('sorts newest execution first and maps buyer/seller names', () {
      final ordersById = {
        's1': _order('s1', 'seller'),
        'b1': _order('b1', 'buyer'),
      };
      final logs = tradeLogsFromExecutions(
        executions: [
          _execution(
            id: 'e1',
            sellOrderId: 's1',
            buyOrderId: 'b1',
            at: DateTime.utc(2024, 1, 1, 10),
            price: 50,
          ),
          _execution(
            id: 'e2',
            sellOrderId: 's1',
            buyOrderId: 'b1',
            at: DateTime.utc(2024, 1, 1, 12),
            price: 60,
          ),
        ],
        ordersById: ordersById,
        nameForPlayer: (id) => id == 'seller' ? 'Alice' : 'Bob',
      );

      expect(logs.length, 2);
      expect(logs.first.price, 60);
      expect(logs.first.sellerName, 'Alice');
      expect(logs.first.buyerName, 'Bob');
      expect(logs.last.price, 50);
    });

    test('empty executions yields empty list', () {
      expect(
        tradeLogsFromExecutions(
          executions: const [],
          ordersById: const {},
          nameForPlayer: (_) => 'x',
        ),
        isEmpty,
      );
    });
  });
}
