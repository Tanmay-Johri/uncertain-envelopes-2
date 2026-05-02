import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';

void main() {
  group('mockBidAskMidpointForGameTitle', () {
    test('returns sample-book midpoint for Forex Masters', () {
      expect(mockBidAskMidpointForGameTitle('Forex Masters'), 150.0);
    });

    test('returns midpoint for Crypto Sim pending-orders mock title', () {
      expect(mockBidAskMidpointForGameTitle('Crypto Sim 2024'), 150.0);
    });

    test('returns null when no mocked book', () {
      expect(mockBidAskMidpointForGameTitle('Start-up Equity'), isNull);
    });
  });
}
