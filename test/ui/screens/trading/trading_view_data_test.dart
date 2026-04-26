import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_view_data.dart';

void main() {
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
