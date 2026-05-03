import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_view_data.dart';

void main() {
  group('computeBidAskMidpoint', () {
    test('is null when either side is empty', () {
      expect(
        computeBidAskMidpoint(const [], const [OrderBookLevel(price: 1, quantity: 1)]),
        isNull,
      );
      expect(
        computeBidAskMidpoint(const [OrderBookLevel(price: 1, quantity: 1)], const []),
        isNull,
      );
    });

    test('uses max bid and min ask even when lists are not sorted', () {
      expect(
        computeBidAskMidpoint(
          const [
            OrderBookLevel(price: 10, quantity: 1),
            OrderBookLevel(price: 12, quantity: 1),
          ],
          const [
            OrderBookLevel(price: 20, quantity: 1),
            OrderBookLevel(price: 18, quantity: 1),
          ],
        ),
        15.0,
      );
    });
  });

  group('TradeLogEntry', () {
    test('stores all fields', () {
      const e = TradeLogEntry(
        sellerName: 'Alice',
        buyerName: 'Bob',
        quantity: 5,
        price: 149.50,
      );
      expect(e.sellerName, 'Alice');
      expect(e.buyerName, 'Bob');
      expect(e.quantity, 5);
      expect(e.price, 149.50);
    });

    test('quantity can be 1', () {
      const e = TradeLogEntry(
          sellerName: 'X', buyerName: 'Y', quantity: 1, price: 100);
      expect(e.quantity, 1);
    });

    test('price can be a whole number', () {
      const e = TradeLogEntry(
          sellerName: 'X', buyerName: 'Y', quantity: 2, price: 150);
      expect(e.price, 150.0);
    });
  });

  group('GameTradingViewData', () {
    test('personalOrders defaults to empty when omitted', () {
      const d = GameTradingViewData(
        gameTitle: 't',
        description: 'd',
        isViewerAdmin: false,
        currentPlayerId: 'p',
        isTimed: false,
        tradingTimeRemaining: null,
        deltaCash: 0,
        deltaEnvelopes: 0,
        orderBookBids: [],
        orderBookAsks: [],
        marketPrice: 1,
        priceHistory: [],
        chartSessionElapsed: Duration.zero,
      );
      expect(d.personalOrders, isEmpty);
    });

    test('tradeLogs defaults to empty when omitted', () {
      const d = GameTradingViewData(
        gameTitle: 't',
        description: 'd',
        isViewerAdmin: false,
        currentPlayerId: 'p',
        isTimed: false,
        tradingTimeRemaining: null,
        deltaCash: 0,
        deltaEnvelopes: 0,
        orderBookBids: [],
        orderBookAsks: [],
        marketPrice: 1,
        priceHistory: [],
        chartSessionElapsed: Duration.zero,
      );
      expect(d.tradeLogs, isEmpty);
    });

    test('tradeLogs stores provided entries', () {
      const logs = [
        TradeLogEntry(sellerName: 'A', buyerName: 'B', quantity: 3, price: 50),
      ];
      const d = GameTradingViewData(
        gameTitle: 't',
        description: 'd',
        isViewerAdmin: false,
        currentPlayerId: 'p',
        isTimed: false,
        tradingTimeRemaining: null,
        deltaCash: 0,
        deltaEnvelopes: 0,
        orderBookBids: [],
        orderBookAsks: [],
        marketPrice: 1,
        priceHistory: [],
        chartSessionElapsed: Duration.zero,
        tradeLogs: logs,
      );
      expect(d.tradeLogs.length, 1);
      expect(d.tradeLogs.first.sellerName, 'A');
    });
  });
}
