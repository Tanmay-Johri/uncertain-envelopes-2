import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/usd_limit_price_display.dart';

void main() {
  group('formatUsdLimitForActiveOrder', () {
    test('cent-aligned values use locale currency with two decimals', () {
      expect(formatUsdLimitForActiveOrder(151), r'$151.00');
      expect(formatUsdLimitForActiveOrder(151.0), r'$151.00');
      expect(formatUsdLimitForActiveOrder(151.88), r'$151.88');
      expect(formatUsdLimitForActiveOrder(10), r'$10.00');
    });

    test('non-cent values show trimmed fraction up to five digits (min 2)', () {
      expect(formatUsdLimitForActiveOrder(151.876), r'$151.876');
      expect(formatUsdLimitForActiveOrder(151.87654), r'$151.87654');
      expect(formatUsdLimitForActiveOrder(1.23456), r'$1.23456');
    });

    test('trims trailing zeros in extended form but keeps at least two', () {
      expect(formatUsdLimitForActiveOrder(151.1), r'$151.10');
      expect(formatUsdLimitForActiveOrder(151.120), r'$151.12');
      expect(formatUsdLimitForActiveOrder(151.12340), r'$151.1234');
    });

    test('float noise near a cent still formats as two decimals', () {
      expect(formatUsdLimitForActiveOrder(151.88 + 1e-12), r'$151.88');
    });

    test('NaN and infinity fall back to zero currency', () {
      expect(formatUsdLimitForActiveOrder(double.nan), r'$0.00');
      expect(formatUsdLimitForActiveOrder(double.infinity), r'$0.00');
      expect(formatUsdLimitForActiveOrder(double.negativeInfinity), r'$0.00');
    });

    test('negative prices preserve sign in both modes', () {
      expect(formatUsdLimitForActiveOrder(-10), r'-$10.00');
      expect(formatUsdLimitForActiveOrder(-1.2345), r'-$1.2345');
    });
  });
}
