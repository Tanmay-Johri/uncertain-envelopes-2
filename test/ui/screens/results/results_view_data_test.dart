import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/results/results_mock_data.dart';

void main() {
  group('GameResultsViewData.withEnvelopeUsd', () {
    test('recomputes PnL from deltas and sorts descending (PRD formula)', () {
      final base = mockGameResultsViewDataForAdmin();
      final snapshot = base.withEnvelopeUsd(145);

      expect(snapshot.players.map((p) => p.playerId), [
        'p_cw',
        'p_admin',
        'p_tk',
        'p_js',
      ]);
      expect(snapshot.players[0].pnl, closeTo(650, 1e-9));
      expect(snapshot.players[1].pnl, closeTo(210, 1e-9));
      expect(snapshot.players[2].pnl, closeTo(180, 1e-9));
      expect(snapshot.players[3].pnl, closeTo(120, 1e-9));
    });
  });
}
