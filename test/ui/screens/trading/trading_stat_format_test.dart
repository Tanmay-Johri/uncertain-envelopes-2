import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_stat_format.dart';

void main() {
  group('formatTradingDeltaCash', () {
    test('omits plus for positive', () {
      expect(formatTradingDeltaCash(12500), r'$12,500');
    });

    test('prefixes minus before dollar for negative', () {
      expect(formatTradingDeltaCash(-12500), r'-$12,500');
    });

    test('zero is neutral currency', () {
      expect(formatTradingDeltaCash(0), r'$0');
    });
  });

  group('formatTradingDeltaEnvelopes', () {
    test('omits plus for positive', () {
      expect(formatTradingDeltaEnvelopes(45), '45');
    });

    test('keeps minus for negative', () {
      expect(formatTradingDeltaEnvelopes(-45), '-45');
    });
  });
}
