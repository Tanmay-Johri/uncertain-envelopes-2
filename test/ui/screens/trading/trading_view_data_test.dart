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
  });
}
