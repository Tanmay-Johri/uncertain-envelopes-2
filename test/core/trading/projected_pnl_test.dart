import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/trading/projected_pnl.dart';

void main() {
  test('HTML mock: 12_500, -45 env, 125 → 6_875', () {
    expect(projectedPnlUsd(12500, -45, 125), 6875.0);
  });

  test('no envelopes: pure cash', () {
    expect(projectedPnlUsd(100, 0, 99), 100);
  });

  test('zero assumption leaves only cash (envelope term zero)', () {
    expect(projectedPnlUsd(50, -3, 0), 50);
  });

  test('envelopeValueForZeroProjectedPnl solves deltaCash + v * dE = 0', () {
    expect(envelopeValueForZeroProjectedPnl(12500, -45), closeTo(277.777777, 1e-6));
    expect(envelopeValueForZeroProjectedPnl(0, -1), 0.0);
    expect(envelopeValueForZeroProjectedPnl(100, 2), -50.0);
  });

  test('envelopeValueForZeroProjectedPnl is null when envelope term absent', () {
    expect(envelopeValueForZeroProjectedPnl(100, 0), isNull);
  });
}
