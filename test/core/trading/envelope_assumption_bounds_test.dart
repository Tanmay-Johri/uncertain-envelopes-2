import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_assumption_bounds.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_value_parse.dart';

void main() {
  group('examples you gave (per-endpoint rules)', () {
    test('75, 225 → 70, 300', () {
      final b = envelopeSliderBoundsFromRaws(75, 225);
      expect(b.min, 70);
      expect(b.max, 300);
    });

    test('raw lower 0.65 → 0; raw upper 0.65 → 1', () {
      expect(envelopeSliderBoundsFromRaws(0.65, 1).min, 0);
      expect(envelopeSliderBoundsFromRaws(0, 0.65).max, 1);
    });

    test('raw lower 1.25 → 1; raw upper 1.25 → 10', () {
      expect(envelopeSliderBoundsFromRaws(1.25, 10).min, 1);
      expect(envelopeSliderBoundsFromRaws(0, 1.25).max, 10);
    });

    test('raw lower 19 → 10; raw upper 19 → 20', () {
      expect(envelopeSliderBoundsFromRaws(19, 100).min, 10);
      expect(envelopeSliderBoundsFromRaws(0, 19).max, 20);
    });
  });

  group('envelopeSliderBoundsForCenter', () {
    test('0.65: (0, 1) tier', () {
      final b = envelopeSliderBoundsForCenter(0.65);
      expect(b.min, 0);
      expect(b.max, 1);
    });

    test('2.5: 1.25, 3.75 → 1, 10', () {
      final b = envelopeSliderBoundsForCenter(2.5);
      expect(b.min, 1);
      expect(b.max, 10);
    });

    test('1: 0.5, 1.5 → 0, 10', () {
      final b = envelopeSliderBoundsForCenter(1);
      expect(b.min, 0);
      expect(b.max, 10);
    });

    test('150 → 70, 300', () {
      final b = envelopeSliderBoundsForCenter(150);
      expect(b.min, 70);
      expect(b.max, 300);
    });

    test('v=0 → 0, 0', () {
      final b = envelopeSliderBoundsForCenter(0);
      expect(b.min, 0);
      expect(b.max, 0);
    });

    test('v=10: 5, 15 → 5, 20', () {
      final b = envelopeSliderBoundsForCenter(10);
      expect(b.min, 5);
      expect(b.max, 20);
    });

    test('v=2: rawL=1 → min 0', () {
      final b = envelopeSliderBoundsForCenter(2);
      expect(isCloseTo(0.5 * 2, 1.0), isTrue);
      expect(b.min, 0);
      expect(b.max, 10);
    });

    test('v=0.4: (0, 1)', () {
      final b = envelopeSliderBoundsForCenter(0.4);
      expect(b.min, 0);
      expect(b.max, 1);
    });

    test('v=2/3: rawU=1, max=1', () {
      const v = 2.0 / 3.0;
      final b = envelopeSliderBoundsForCenter(v);
      expect(b.max, 1);
    });

    test('v=384: 100, 600', () {
      final b = envelopeSliderBoundsForCenter(384);
      expect(b.min, 100);
      expect(b.max, 600);
    });

    test('v=40: 20, 60', () {
      final b = envelopeSliderBoundsForCenter(40);
      expect(b.min, 20);
      expect(b.max, 60);
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
