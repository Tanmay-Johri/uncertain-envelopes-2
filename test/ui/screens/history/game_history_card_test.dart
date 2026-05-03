import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_card.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_view_data.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GameHistoryEntry _entry({
  String id = 'gh-1',
  String title = 'Alpha Market',
  String description = 'Forex volatility',
  double viewerPnl = 240,
  String securityType = 'Public',
  bool isRanked = true,
  String adminName = 'MasterTrader',
  double? envelopePriceUsd = 12.50,
  DateTime? startedAt,
  DateTime? endedAt,
  List<GameHistoryPlayerResult> playerResults = const [
    GameHistoryPlayerResult(playerId: 'p1', displayName: 'Player1', pnl: 100),
    GameHistoryPlayerResult(playerId: 'p2', displayName: 'Player2', pnl: -20),
    GameHistoryPlayerResult(
        playerId: 'p3', displayName: 'CryptoKing99', pnl: 160),
  ],
}) {
  return GameHistoryEntry(
    id: id,
    title: title,
    description: description,
    viewerPnl: viewerPnl,
    securityType: securityType,
    isRanked: isRanked,
    adminName: adminName,
    envelopePriceUsd: envelopePriceUsd,
    startedAt: startedAt,
    endedAt: endedAt,
    playerResults: playerResults,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget widget, {
  Size size = const Size(480, 1800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: widget,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GameHistoryCard — collapsed', () {
    testWidgets('shows title', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(), isExpanded: false, onTap: () {}),
      );
      expect(find.text('Alpha Market'), findsOneWidget);
    });

    testWidgets('shows description', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(), isExpanded: false, onTap: () {}),
      );
      expect(find.text('Forex volatility'), findsOneWidget);
    });

    testWidgets('shows viewer PnL formatted', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(viewerPnl: 240), isExpanded: false, onTap: () {}),
      );
      expect(find.text('+\$240'), findsOneWidget);
    });

    testWidgets('shows expand_more chevron when collapsed', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(), isExpanded: false, onTap: () {}),
      );
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets('does NOT show security/admin/envelope/players', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(), isExpanded: false, onTap: () {}),
      );
      expect(find.text('SECURITY TYPE'), findsNothing);
      expect(find.text('ADMIN'), findsNothing);
      expect(find.text('ENVELOPE PRICE'), findsNothing);
      expect(find.text('PLAYERS PNL'), findsNothing);
      expect(find.text('@MasterTrader'), findsNothing);
    });

    testWidgets('tapping header calls onTap exactly once', (tester) async {
      int taps = 0;
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(), isExpanded: false, onTap: () => taps++),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      expect(taps, 1);
    });
  });

  // -------------------------------------------------------------------------

  group('GameHistoryCard — expanded', () {
    testWidgets('shows expand_less chevron when expanded', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(), isExpanded: true, onTap: () {}),
      );
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    testWidgets('shows SECURITY TYPE label and value', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(securityType: 'Private'),
            isExpanded: true,
            onTap: () {}),
      );
      expect(find.text('SECURITY TYPE'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('shows STATUS label and Ranked value', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(isRanked: true), isExpanded: true, onTap: () {}),
      );
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('Ranked'), findsOneWidget);
    });

    testWidgets('shows STATUS label and Casual when isRanked false', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(isRanked: false), isExpanded: true, onTap: () {}),
      );
      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Ranked'), findsNothing);
    });

    testWidgets('Ranked value is white (not green)', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(isRanked: true), isExpanded: true, onTap: () {}),
      );
      final rankedWidget = tester.widget<Text>(find.text('Ranked'));
      expect(rankedWidget.style?.color, AppColors.textPrimary);
    });

    testWidgets('shows ADMIN prefixed with @', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(adminName: 'MasterTrader'),
            isExpanded: true,
            onTap: () {}),
      );
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('@MasterTrader'), findsOneWidget);
    });

    testWidgets('shows ENVELOPE PRICE with dollar format', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(envelopePriceUsd: 12.50),
            isExpanded: true,
            onTap: () {}),
      );
      expect(find.text('ENVELOPE PRICE'), findsOneWidget);
      expect(find.text('\$12.50'), findsOneWidget);
    });

    testWidgets('shows \$— when envelope is null', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(envelopePriceUsd: null),
            isExpanded: true,
            onTap: () {}),
      );
      expect(find.text(r'$—'), findsOneWidget);
    });

    testWidgets('shows STARTED label and formatted time', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
          entry: _entry(startedAt: DateTime.utc(2024, 10, 24, 14, 30)),
          isExpanded: true,
          onTap: () {},
        ),
      );
      expect(find.text('STARTED'), findsOneWidget);
      expect(find.text('Oct 24, 14:30'), findsOneWidget);
    });

    testWidgets('shows ENDED label and formatted time', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
          entry: _entry(endedAt: DateTime.utc(2024, 10, 24, 16, 0)),
          isExpanded: true,
          onTap: () {},
        ),
      );
      expect(find.text('ENDED'), findsOneWidget);
      expect(find.text('Oct 24, 16:00'), findsOneWidget);
    });

    testWidgets('shows — when startedAt is null', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
          entry: _entry(startedAt: null),
          isExpanded: true,
          onTap: () {},
        ),
      );
      expect(find.text('STARTED'), findsOneWidget);
      // At least one '—' is present (could also be endedAt if both null)
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('shows — when endedAt is null', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
          entry: _entry(endedAt: null),
          isExpanded: true,
          onTap: () {},
        ),
      );
      expect(find.text('ENDED'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('shows all player names in PLAYERS PNL section', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(entry: _entry(), isExpanded: true, onTap: () {}),
      );
      expect(find.text('PLAYERS PNL'), findsOneWidget);
      expect(find.text('Player1'), findsOneWidget);
      expect(find.text('Player2'), findsOneWidget);
      expect(find.text('CryptoKing99'), findsOneWidget);
    });

    testWidgets('empty playerResults — PLAYERS PNL section not shown', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(playerResults: const []),
            isExpanded: true,
            onTap: () {}),
      );
      expect(find.text('PLAYERS PNL'), findsNothing);
    });

    testWidgets('single player result renders', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
          entry: _entry(playerResults: const [
            GameHistoryPlayerResult(playerId: 'x', displayName: 'Solo', pnl: 50),
          ]),
          isExpanded: true,
          onTap: () {},
        ),
      );
      expect(find.text('Solo'), findsOneWidget);
      expect(find.text('+\$50'), findsOneWidget);
    });

    testWidgets('10 player results all render', (tester) async {
      final results = List.generate(
        10,
        (i) => GameHistoryPlayerResult(
          playerId: 'p$i',
          displayName: 'Player $i',
          pnl: i.toDouble(),
        ),
      );
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(playerResults: results),
            isExpanded: true,
            onTap: () {}),
      );
      for (var i = 0; i < 10; i++) {
        expect(find.text('Player $i'), findsOneWidget);
      }
    });
  });

  // -------------------------------------------------------------------------

  group('GameHistoryCard — PnL colors', () {
    Color? _pnlTextColor(WidgetTester tester, String text) {
      final widget = tester.widget<Text>(find.text(text).first);
      return widget.style?.color;
    }

    testWidgets('positive viewerPnl → primary (green)', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(viewerPnl: 100), isExpanded: false, onTap: () {}),
      );
      expect(_pnlTextColor(tester, '+\$100'), AppColors.primary);
    });

    testWidgets('negative viewerPnl → secondary (red)', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(viewerPnl: -50), isExpanded: false, onTap: () {}),
      );
      expect(_pnlTextColor(tester, '-\$50'), AppColors.secondary);
    });

    testWidgets('zero viewerPnl → textPrimary (white)', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(viewerPnl: 0), isExpanded: false, onTap: () {}),
      );
      expect(_pnlTextColor(tester, '\$0'), AppColors.textPrimary);
    });

    testWidgets('positive epsilon (0.001) → green (raw float, not rounded display)', (tester) async {
      // 0.001 rounds to $0 in display, but _pnlColor uses the raw float → green.
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(viewerPnl: 0.001), isExpanded: false, onTap: () {}),
      );
      // There is exactly one '$0' Text widget in the header for this case.
      final dollarZeroWidgets = find.byType(Text).evaluate()
          .map((e) => e.widget as Text)
          .where((w) => w.data == '\$0')
          .toList();
      expect(dollarZeroWidgets, isNotEmpty);
      expect(dollarZeroWidgets.first.style?.color, AppColors.primary);
    });

    testWidgets('negative epsilon (-0.001) → red (raw float, not rounded display)', (tester) async {
      // -0.001 rounds to $0 in display, but _pnlColor uses the raw float → red.
      await _pump(
        tester,
        GameHistoryCard(
            entry: _entry(viewerPnl: -0.001), isExpanded: false, onTap: () {}),
      );
      final dollarZeroWidgets = find.byType(Text).evaluate()
          .map((e) => e.widget as Text)
          .where((w) => w.data == '\$0')
          .toList();
      expect(dollarZeroWidgets, isNotEmpty);
      expect(dollarZeroWidgets.first.style?.color, AppColors.secondary);
    });
  });

  // -------------------------------------------------------------------------

  group('GameHistoryCard — overflow / boundary', () {
    testWidgets('very long title does not overflow', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
          entry: _entry(title: 'A' * 80),
          isExpanded: false,
          onTap: () {},
        ),
      );
      // no RenderFlex overflow exception
    });

    testWidgets('very long player display name does not overflow', (tester) async {
      await _pump(
        tester,
        GameHistoryCard(
          entry: _entry(playerResults: [
            GameHistoryPlayerResult(
              playerId: 'p1',
              displayName: 'V' * 40,
              pnl: 50,
            ),
          ]),
          isExpanded: true,
          onTap: () {},
        ),
      );
    });
  });
}
