import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_assumption_bounds.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_value_parse.dart';

void main() {
  group('envelopeSliderBoundsForCenter', () {
    test('0.65: raw 0.325, 0.975 (3dp) → grid, clamp 0–1', () {
      final b = envelopeSliderBoundsForCenter(0.65);
      expect(b.min, moreOrLessEquals(0.3));
      expect(b.max, 1.0);
    });

    test('6.5: raw 3.25, 9.75 → 3, 10 after clamp 0–10', () {
      final b = envelopeSliderBoundsForCenter(6.5);
      expect(b.min, 3.0);
      expect(b.max, 10.0);
    });

    test('1: raw 0.5, 1.5 → 0.5, 1.5 in 0–10 tier (not full 0–10 span)', () {
      final b = envelopeSliderBoundsForCenter(1);
      expect(b.min, 0.5);
      expect(b.max, 1.5);
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

    test('v=10 uses >=10 tier (trunc integers)', () {
      final b = envelopeSliderBoundsForCenter(10);
      expect(b.min, 5.0);
      expect(b.max, 15.0);
    });

    test('raw lower exactly 1 → min display 0 (v=2)', () {
      final b = envelopeSliderBoundsForCenter(2);
      expect(isCloseTo(0.5 * 2, 1.0), isTrue);
      expect(b.min, 0);
      expect(b.max, 3.0);
    });

    test('v=0.4: raw 0.2, 0.6 → 0.2, 0.6', () {
      final b = envelopeSliderBoundsForCenter(0.4);
      expect(b.min, 0.2);
      expect(b.max, 0.6);
    });

    test('v=2.5: raw 1.25, 3.75 → 1, 4 (not 0–10 only)', () {
      final b = envelopeSliderBoundsForCenter(2.5);
      expect(b.min, 1.0);
      expect(b.max, 4.0);
    });

    test('v=2/3: rawU=1.0, max capped to 1 (≈1 rule)', () {
      const v = 2.0 / 3.0;
      final b = envelopeSliderBoundsForCenter(v);
      expect(
        1.5 * v,
        moreOrLessEquals(1.0),
      );
      expect(b.max, 1.0);
    });

    test('v=5/6: rawU=1.25, rawL=0.41…, tight bounds under 0–1 cap', () {
      const v = 1.25 / 1.5; // 5/6
      final b = envelopeSliderBoundsForCenter(v);
      expect(b.max, 1.0);
      expect(b.min, lessThanOrEqualTo(1.0));
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
