import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/results/game_results_pnl.dart';

void main() {
  group('computeFinalPnlFromEnvelope', () {
    test('null envelope yields unknown PnL', () {
      expect(
        computeFinalPnlFromEnvelope(
          deltaCash: 100,
          deltaEnvelopes: 3,
          envelopePriceUsd: null,
        ),
        isNull,
      );
    });

    test('matches PRD: deltaCash + envelope * deltaEnvelopes', () {
      expect(
        computeFinalPnlFromEnvelope(
          deltaCash: 500,
          deltaEnvelopes: -2,
          envelopePriceUsd: 145,
        ),
        500 + (-2) * 145,
      );
    });
  });

  group('comparePnlDescendingKnownLast', () {
    test('puts null last', () {
      final rows = [3.0, null, -1.0, 10.0, null];
      rows.sort((a, b) => comparePnlDescendingKnownLast(a, b));
      expect(rows, [10.0, 3.0, -1.0, null, null]);
    });
  });
}
