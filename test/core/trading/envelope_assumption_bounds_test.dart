import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/envelope_assumption_bounds.dart';

void main() {
  group('envelopeSliderBoundsFromRaws', () {
    test('150 → step 100; 75,225 → 0, 300', () {
      final b = envelopeSliderBoundsFromRaws(
        75,
        225,
        assumptionForStep: 150,
      );
      expect(b.min, 0);
      expect(b.max, 300);
    });

    test('anchor 75 ≥ 10: grids provided raws 75,225 with step 10 → 70, 230', () {
      final b = envelopeSliderBoundsFromRaws(
        75,
        225,
        assumptionForStep: 75,
      );
      expect(b.min, 70);
      expect(b.max, 230);
    });

    test('anchor in [1,10): returns 0,10 regardless of raws', () {
      final b = envelopeSliderBoundsFromRaws(
        99,
        999,
        assumptionForStep: 5,
      );
      expect(b.min, 0);
      expect(b.max, 10);
    });

    test('anchor in (0,1): returns 0,1 regardless of raws', () {
      final b = envelopeSliderBoundsFromRaws(
        99,
        999,
        assumptionForStep: 0.5,
      );
      expect(b.min, 0);
      expect(b.max, 1);
    });
  });

  group('envelopeSliderBoundsForCenter', () {
    test('150 → 0, 300', () {
      final b = envelopeSliderBoundsForCenter(150);
      expect(b.min, 0);
      expect(b.max, 300);
    });

    test('0 < v < 1 → fixed 0, 1', () {
      final b = envelopeSliderBoundsForCenter(0.65);
      expect(b.min, 0);
      expect(b.max, 1.0);
    });

    test('1 ≤ v < 10 → fixed 0, 10', () {
      expect(envelopeSliderBoundsForCenter(2.5), (min: 0, max: 10));
      expect(envelopeSliderBoundsForCenter(1), (min: 0, max: 10));
      expect(envelopeSliderBoundsForCenter(9.99), (min: 0, max: 10));
    });

    test('v=0 → 0, 0', () {
      final b = envelopeSliderBoundsForCenter(0);
      expect(b.min, 0);
      expect(b.max, 0);
    });

    test('v=10: step 10 → 0, 20', () {
      final b = envelopeSliderBoundsForCenter(10);
      expect(b.min, 0);
      expect(b.max, 20);
    });

    test('v=2 in [1,10) tier → 0, 10 (not raw-based grid)', () {
      final b = envelopeSliderBoundsForCenter(2);
      expect(b.min, 0);
      expect(b.max, 10);
    });

    test('v=0.4 in (0,1) tier → 0, 1', () {
      final b = envelopeSliderBoundsForCenter(0.4);
      expect(b.min, 0);
      expect(b.max, 1.0);
    });

    test('v=2/3 in (0,1) tier → 0, 1', () {
      const v = 2.0 / 3.0;
      final b = envelopeSliderBoundsForCenter(v);
      expect(b.min, 0);
      expect(b.max, 1.0);
    });

    test('v=384: step 100 → 100, 600', () {
      final b = envelopeSliderBoundsForCenter(384);
      expect(b.min, 100);
      expect(b.max, 600);
    });

    test('v=40: step 10 → 20, 60', () {
      final b = envelopeSliderBoundsForCenter(40);
      expect(b.min, 20);
      expect(b.max, 60);
    });

    test('v=19: step 10, raw 9.5 / 28.5 → 0, 30', () {
      final b = envelopeSliderBoundsForCenter(19);
      expect(b.min, 0);
      expect(b.max, 30);
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
