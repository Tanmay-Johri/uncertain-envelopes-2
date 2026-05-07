import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/limit_price_input.dart';

void main() {
  group('limitPriceFractionDigitsFromRaw', () {
    test('no dot implies minimum two digits', () {
      expect(limitPriceFractionDigitsFromRaw('150'), kLimitPriceMinFractionDigits);
    });

    test('dot with no digits after still uses two', () {
      expect(limitPriceFractionDigitsFromRaw('150.'), kLimitPriceMinFractionDigits);
    });

    test('respects extra typed decimal places', () {
      expect(limitPriceFractionDigitsFromRaw('152.876'), 3);
      expect(limitPriceFractionDigitsFromRaw('1.2345'), 4);
    });

    test('single fractional digit bumps to two for display', () {
      expect(limitPriceFractionDigitsFromRaw('3.5'), kLimitPriceMinFractionDigits);
    });
  });

  group('formatLimitPriceForField', () {
    test('default is two fraction digits', () {
      expect(formatLimitPriceForField(150), '150.00');
      expect(formatLimitPriceForField(100, rawHint: null), '100.00');
    });

    test('hint with extra decimals preserves precision', () {
      expect(formatLimitPriceForField(152.876, rawHint: '152.876'), '152.876');
      expect(formatLimitPriceForField(1.2345, rawHint: '1.2345'), '1.2345');
    });
  });

  group('normalizeLimitPriceFieldText', () {
    test('empty uses fallback market', () {
      expect(
        normalizeLimitPriceFieldText('', 150.0),
        '150.00',
      );
    });

    test('invalid uses fallback', () {
      expect(
        normalizeLimitPriceFieldText('abc', 99.5),
        '99.50',
      );
      expect(
        normalizeLimitPriceFieldText('-1', 10.0),
        '10.00',
      );
      expect(
        normalizeLimitPriceFieldText('0', 10.0),
        '10.00',
      );
    });

    test('valid formats with at least two fraction digits', () {
      expect(normalizeLimitPriceFieldText('149.25', 150.0), '149.25');
      expect(normalizeLimitPriceFieldText('  3.5  ', 1.0), '3.50');
      expect(normalizeLimitPriceFieldText('150', 1.0), '150.00');
    });

    test('valid preserves extra fractional digits from user input', () {
      expect(
        normalizeLimitPriceFieldText('152.876', 150.0),
        '152.876',
      );
    });
  });

  group('parseLimitPriceForSubmit', () {
    test('empty is null', () {
      expect(parseLimitPriceForSubmit(''), isNull);
    });

    test('exact double', () {
      expect(parseLimitPriceForSubmit('149.25'), 149.25);
      expect(parseLimitPriceForSubmit('3'), 3.0);
    });

    test('invalid or non-positive is null', () {
      expect(parseLimitPriceForSubmit('x'), isNull);
      expect(parseLimitPriceForSubmit('0'), isNull);
      expect(parseLimitPriceForSubmit('-2'), isNull);
    });
  });
}
