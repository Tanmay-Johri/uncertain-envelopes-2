import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_assumption_bounds.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_value_parse.dart';

void main() {
  group('envelopeSliderBoundsFromRaws (no implied center v)', () {
    test('upper raw 1.25 alone → nice upper 10; lower placeholder', () {
      final b = envelopeSliderBoundsFromRaws(0, 1.25, maxCap: 10);
      expect(b.max, 10.0);
    });

    test('upper raw 0.975 → nice upper 1', () {
      final b = envelopeSliderBoundsFromRaws(0, 0.975, minCap: 0, maxCap: 1);
      expect(b.max, 1.0);
    });

    test('lower raw 0.325 → nice lower 0.1', () {
      final b = envelopeSliderBoundsFromRaws(0.325, 1, minCap: 0, maxCap: 1);
      expect(b.min, moreOrLessEquals(0.1));
    });
  });

  group('envelopeSliderBoundsForCenter', () {
    test('0.65: raw 0.325, 0.975 → decade 0.1, 1 (clamp 0–1)', () {
      final b = envelopeSliderBoundsForCenter(0.65);
      expect(b.min, 0.1);
      expect(b.max, 1.0);
    });

    test('2.5: raw 1.25, 3.75 → decade 1, 10 (not digit grid 1–4)', () {
      final b = envelopeSliderBoundsForCenter(2.5);
      expect(b.min, 1.0);
      expect(b.max, 10.0);
    });

    test('1: raw 0.5, 1.5 within [0,10] tier', () {
      final b = envelopeSliderBoundsForCenter(1);
      expect(b.min, 0.1);
      expect(b.max, 10.0);
    });

    test('150 (mock dashboard) → 70, 230 (int path, raws >= 10)', () {
      final b = envelopeSliderBoundsForCenter(150);
      expect(b.min, 70);
      expect(b.max, 230);
    });

    test('v=0 → 0, 0', () {
      final b = envelopeSliderBoundsForCenter(0);
      expect(b.min, 0);
      expect(b.max, 0);
    });

    test('v=10 uses int path: 5, 15', () {
      final b = envelopeSliderBoundsForCenter(10);
      expect(b.min, 5.0);
      expect(b.max, 15.0);
    });

    test('raw lower exactly 1 → min display 0 (v=2)', () {
      final b = envelopeSliderBoundsForCenter(2);
      expect(isCloseTo(0.5 * 2, 1.0), isTrue);
      expect(b.min, 0);
      expect(b.max, 10.0);
    });

    test('v=0.4: raw 0.2, 0.6 → decade, clamp 0–1', () {
      final b = envelopeSliderBoundsForCenter(0.4);
      expect(b.min, 0.1);
      expect(b.max, 1.0);
    });

    test('v=2/3: rawU=1, max=1 (≈1 rule)', () {
      const v = 2.0 / 3.0;
      final b = envelopeSliderBoundsForCenter(v);
      expect(b.max, 1.0);
    });

    test('v=384: 100, 600', () {
      final b = envelopeSliderBoundsForCenter(384);
      expect(b.min, 100.0);
      expect(b.max, 600.0);
    });

    test('v=40: 20, 60', () {
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
