import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/results/game_results_envelope_edit.dart';

void main() {
  group('parseEnvelopePriceUsd', () {
    test('empty and whitespace → null', () {
      expect(parseEnvelopePriceUsd(''), isNull);
      expect(parseEnvelopePriceUsd('   '), isNull);
    });

    test('integers and decimals', () {
      expect(parseEnvelopePriceUsd('100'), 100);
      expect(parseEnvelopePriceUsd('145'), 145);
      expect(parseEnvelopePriceUsd('145.5'), 145.5);
      expect(parseEnvelopePriceUsd('145.50'), 145.50);
    });

    test('trailing dot completes to .0', () {
      expect(parseEnvelopePriceUsd('10.'), 10);
      expect(parseEnvelopePriceUsd('0.'), 0);
    });

    test('up to five fractional digits', () {
      expect(parseEnvelopePriceUsd('1.23456'), 1.23456);
      expect(parseEnvelopePriceUsd('151.87654'), 151.87654);
    });

    test('six fractional digits rejects', () {
      expect(parseEnvelopePriceUsd('1.234567'), isNull);
    });

    test('negative', () {
      expect(parseEnvelopePriceUsd('-50'), -50);
      expect(parseEnvelopePriceUsd('-  50.25'), -50.25);
    });

    test('invalid tokens reject', () {
      expect(parseEnvelopePriceUsd('abc'), isNull);
      expect(parseEnvelopePriceUsd('12.34.56'), isNull);
      expect(parseEnvelopePriceUsd(' '), isNull);
      expect(parseEnvelopePriceUsd('.'), isNull);
    });
  });

  group('envelopePriceSeedForEditing', () {
    test('null → empty', () {
      expect(envelopePriceSeedForEditing(null), '');
    });

    test('cent values keep two decimals minimum', () {
      expect(envelopePriceSeedForEditing(145), '145.00');
      expect(envelopePriceSeedForEditing(145.88), '145.88');
    });

    test('non-cent trims to max five with min two', () {
      expect(envelopePriceSeedForEditing(151.876), '151.876');
      expect(envelopePriceSeedForEditing(151.1), '151.10');
    });
  });
}
