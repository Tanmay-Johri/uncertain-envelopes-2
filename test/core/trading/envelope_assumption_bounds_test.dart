import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_assumption_bounds.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_value_parse.dart';

void main() {
  group('envelopeSliderBoundsForCenter', () {
    test('0.65-style (fractional) → 0, 1', () {
      final b = envelopeSliderBoundsForCenter(0.65);
      expect(b.min, 0);
      expect(b.max, 1);
    });

    test('6.5-style → 0, 10', () {
      final b = envelopeSliderBoundsForCenter(6.5);
      expect(b.min, 0);
      expect(b.max, 10);
    });

    test('150 (mock dashboard) → 70, 230', () {
      final b = envelopeSliderBoundsForCenter(150);
      expect(b.min, 70);
      expect(b.max, 230);
    });

    test('v=0 → 0, 0', () {
      final b = envelopeSliderBoundsForCenter(0);
      expect(b.min, 0);
      expect(b.max, 0);
    });

    test('v=10 uses >=10 tier, not 0–10', () {
      final b = envelopeSliderBoundsForCenter(10);
      expect(b.min, 5.0);
      expect(b.max, 15.0);
    });

    test('v=1 uses 0–10 tier (1 <= v < 10)', () {
      final b = envelopeSliderBoundsForCenter(1);
      expect(b.min, 0);
      expect(b.max, 10);
    });

    test('raw lower exactly 1 → min display 0 (v=2)', () {
      // rawL=1, rawU=3, tier 0–10, rule forces min 0
      final b = envelopeSliderBoundsForCenter(2);
      expect(isCloseTo(0.5 * 2, 1.0), isTrue);
      expect(b.min, 0);
    });

    test('v=0.4 → 0, 1', () {
      final b = envelopeSliderBoundsForCenter(0.4);
      expect(b.min, 0);
      expect(b.max, 1);
    });

    test('v=384: raw 192,576 (3 digits each) → step 10² → 100, 600', () {
      final b = envelopeSliderBoundsForCenter(384);
      expect(b.min, 100.0);
      expect(b.max, 600.0);
    });

    test('v=40: raw 20,60 (2 digits) → step 10¹ → 20, 60', () {
      final b = envelopeSliderBoundsForCenter(40);
      expect(b.min, 20.0);
      expect(b.max, 60.0);
    });
  });

  group('valueFitsInBounds', () {
    test('inside inclusive', () {
      expect(valueFitsInBounds(5, 0, 10), isTrue);
      expect(valueFitsInBounds(0, 0, 10), isTrue);
      expect(valueFitsInBounds(10, 0, 10), isTrue);
    });
    test('outside', () {
      expect(valueFitsInBounds(10.1, 0, 10), isFalse);
      expect(valueFitsInBounds(-0.1, 0, 10), isFalse);
    });
  });
}
