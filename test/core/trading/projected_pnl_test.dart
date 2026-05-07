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
}
