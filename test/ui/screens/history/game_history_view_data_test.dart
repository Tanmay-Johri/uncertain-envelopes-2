import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_view_data.dart';

void main() {
  // ---------------------------------------------------------------------------
  // GameHistoryPlayerResult
  // ---------------------------------------------------------------------------
  group('GameHistoryPlayerResult', () {
    test('stores all fields', () {
      const row = GameHistoryPlayerResult(
        playerId: 'p1',
        displayName: 'Alice',
        pnl: 42.5,
      );
      expect(row.playerId, 'p1');
      expect(row.displayName, 'Alice');
      expect(row.pnl, 42.5);
    });

    test('pnl can be negative', () {
      const row = GameHistoryPlayerResult(
        playerId: 'p2',
        displayName: 'Bob',
        pnl: -99.99,
      );
      expect(row.pnl, -99.99);
    });

    test('pnl can be zero', () {
      const row = GameHistoryPlayerResult(
        playerId: 'p3',
        displayName: 'Carol',
        pnl: 0,
      );
      expect(row.pnl, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // GameHistoryEntry
  // ---------------------------------------------------------------------------
  group('GameHistoryEntry', () {
    GameHistoryEntry buildEntry({
      String id = 'gh-1',
      double viewerPnl = 100,
      double? envelopePriceUsd = 12.50,
      DateTime? startedAt,
      DateTime? endedAt,
      List<GameHistoryPlayerResult> playerResults = const [],
      bool isRanked = true,
    }) {
      return GameHistoryEntry(
        id: id,
        title: 'Alpha Market',
        description: 'Forex volatility',
        viewerPnl: viewerPnl,
        securityType: 'Public',
        isRanked: isRanked,
        adminName: 'MasterTrader',
        envelopePriceUsd: envelopePriceUsd,
        startedAt: startedAt,
        endedAt: endedAt,
        playerResults: playerResults,
      );
    }

    test('stores all fields correctly', () {
      final started = DateTime.utc(2024, 10, 24, 14, 30);
      final ended = DateTime.utc(2024, 10, 24, 16, 0);
      final results = [
        const GameHistoryPlayerResult(playerId: 'p1', displayName: 'Alice', pnl: 50),
      ];
      final e = buildEntry(
        id: 'gh-test',
        viewerPnl: 240,
        envelopePriceUsd: 12.50,
        startedAt: started,
        endedAt: ended,
        playerResults: results,
      );
      expect(e.id, 'gh-test');
      expect(e.title, 'Alpha Market');
      expect(e.viewerPnl, 240);
      expect(e.securityType, 'Public');
      expect(e.isRanked, true);
      expect(e.adminName, 'MasterTrader');
      expect(e.envelopePriceUsd, 12.50);
      expect(e.startedAt, started);
      expect(e.endedAt, ended);
      expect(e.playerResults.length, 1);
    });

    test('viewerPnl positive', () => expect(buildEntry(viewerPnl: 0.01).viewerPnl, greaterThan(0)));
    test('viewerPnl negative', () => expect(buildEntry(viewerPnl: -0.01).viewerPnl, lessThan(0)));
    test('viewerPnl zero', () => expect(buildEntry(viewerPnl: 0).viewerPnl, 0.0));
    test('viewerPnl large positive', () => expect(buildEntry(viewerPnl: 1200).viewerPnl, 1200));
    test('viewerPnl large negative', () => expect(buildEntry(viewerPnl: -9999.99).viewerPnl, -9999.99));

    test('envelopePriceUsd can be null', () {
      expect(buildEntry(envelopePriceUsd: null).envelopePriceUsd, isNull);
    });

    test('envelopePriceUsd can be zero', () {
      expect(buildEntry(envelopePriceUsd: 0).envelopePriceUsd, 0.0);
    });

    test('startedAt can be null', () {
      expect(buildEntry(startedAt: null).startedAt, isNull);
    });

    test('endedAt can be null', () {
      expect(buildEntry(endedAt: null).endedAt, isNull);
    });

    test('startedAt and endedAt can both be set', () {
      final s = DateTime.utc(2024, 10, 5, 9, 0);
      final e = DateTime.utc(2024, 10, 5, 11, 0);
      final entry = buildEntry(startedAt: s, endedAt: e);
      expect(entry.startedAt, s);
      expect(entry.endedAt, e);
    });

    test('playerResults can be empty', () {
      expect(buildEntry(playerResults: const []).playerResults, isEmpty);
    });

    test('playerResults single entry', () {
      const r = GameHistoryPlayerResult(playerId: 'x', displayName: 'X', pnl: 1);
      final e = buildEntry(playerResults: [r]);
      expect(e.playerResults.length, 1);
      expect(e.playerResults.first.playerId, 'x');
    });

    test('playerResults 20 entries — no structural issue', () {
      final results = List.generate(
        20,
        (i) => GameHistoryPlayerResult(
          playerId: 'p$i',
          displayName: 'Player $i',
          pnl: (i % 2 == 0 ? 1 : -1) * i.toDouble(),
        ),
      );
      final e = buildEntry(playerResults: results);
      expect(e.playerResults.length, 20);
    });

    test('isRanked false stores correctly', () {
      expect(buildEntry(isRanked: false).isRanked, isFalse);
    });
  });
}
