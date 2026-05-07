import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_card.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/history/game_history_view_data.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester,
  List<GameHistoryEntry> entries, {
  Size size = const Size(480, 1800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: GoRouter(
        initialLocation: AppRoutes.history,
        routes: [
          GoRoute(
            path: AppRoutes.history,
            builder: (_, _) => GameHistoryScreen(entries: entries),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('stub-home')),
          ),
          GoRoute(
            path: AppRoutes.create,
            builder: (_, _) => const Scaffold(body: Text('stub-create')),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, _) => const Scaffold(body: Text('stub-orders')),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const Scaffold(body: Text('stub-profile')),
          ),
        ],
      ),
    ),
  );
  await tester.pump();
}

List<GameHistoryEntry> _twoEntries() => [
      const GameHistoryEntry(
        id: 'a',
        title: 'Game A',
        description: 'Desc A',
        viewerPnl: 100,
        securityType: 'Public',
        isRanked: true,
        adminName: 'Admin1',
        envelopePriceUsd: 10.0,
        startedAt: null,
        endedAt: null,
        playerResults: [
          GameHistoryPlayerResult(playerId: 'p1', displayName: 'P1', pnl: 100),
        ],
      ),
      const GameHistoryEntry(
        id: 'b',
        title: 'Game B',
        description: 'Desc B',
        viewerPnl: -50,
        securityType: 'Private',
        isRanked: false,
        adminName: 'Admin2',
        envelopePriceUsd: 5.0,
        startedAt: null,
        endedAt: null,
        playerResults: [
          GameHistoryPlayerResult(playerId: 'p2', displayName: 'P2', pnl: -50),
        ],
      ),
    ];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GameHistoryScreen — render', () {
    testWidgets('shows all cards collapsed by default', (tester) async {
      await _pump(tester, _twoEntries());
      expect(find.text('Game A'), findsOneWidget);
      expect(find.text('Game B'), findsOneWidget);
      // Both headers show expand_more (collapsed)
      expect(find.byIcon(Icons.expand_more), findsNWidgets(2));
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets('empty list shows empty state message', (tester) async {
      await _pump(tester, const []);
      expect(find.text('NO GAME HISTORY'), findsOneWidget);
      expect(find.byType(GameHistoryCard), findsNothing);
    });

    testWidgets('single entry renders correctly', (tester) async {
      final entries = [_twoEntries().first];
      await _pump(tester, entries);
      expect(find.text('Game A'), findsOneWidget);
      expect(find.byType(GameHistoryCard), findsOneWidget);
    });

    testWidgets('5-entry mock list: all 5 cards render', (tester) async {
      await _pump(tester, kMockGameHistory());
      expect(find.byType(GameHistoryCard), findsNWidgets(5));
    });

    testWidgets('header shows UNCERTAIN ENVELOPES title', (tester) async {
      await _pump(tester, _twoEntries());
      expect(find.text('UNCERTAIN ENVELOPES'), findsOneWidget);
    });

    testWidgets('positive PnL card shows green text', (tester) async {
      await _pump(tester, [_twoEntries().first]); // viewerPnl = 100
      final pnlTexts = find.byType(Text).evaluate()
          .map((e) => e.widget as Text)
          .where((w) => w.data == '+\$100')
          .toList();
      expect(pnlTexts, isNotEmpty);
      expect(pnlTexts.first.style?.color, AppColors.primary);
    });

    testWidgets('negative PnL card shows red text', (tester) async {
      await _pump(tester, [_twoEntries().last]); // viewerPnl = -50
      final pnlTexts = find.byType(Text).evaluate()
          .map((e) => e.widget as Text)
          .where((w) => w.data == '-\$50')
          .toList();
      expect(pnlTexts, isNotEmpty);
      expect(pnlTexts.first.style?.color, AppColors.secondary);
    });
  });

  // -------------------------------------------------------------------------

  group('GameHistoryScreen — expand / collapse (multi-expand)', () {
    testWidgets('tapping a card expands it', (tester) async {
      await _pump(tester, _twoEntries());
      await tester.tap(find.text('Game A'));
      await tester.pump();
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text('SECURITY TYPE'), findsOneWidget);
    });

    testWidgets('tapping an expanded card collapses it', (tester) async {
      await _pump(tester, _twoEntries());
      // Expand
      await tester.tap(find.text('Game A'));
      await tester.pump();
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      // Collapse
      await tester.tap(find.text('Game A'));
      await tester.pump();
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.text('SECURITY TYPE'), findsNothing);
    });

    testWidgets('multi-expand: two cards can be open simultaneously', (tester) async {
      await _pump(tester, _twoEntries());
      await tester.tap(find.text('Game A'));
      await tester.pump();
      await tester.tap(find.text('Game B'));
      await tester.pump();
      // Both expanded
      expect(find.byIcon(Icons.expand_less), findsNWidgets(2));
    });

    testWidgets('multi-expand: collapsing one does not affect the other', (tester) async {
      await _pump(tester, _twoEntries());
      // Expand both
      await tester.tap(find.text('Game A'));
      await tester.pump();
      await tester.tap(find.text('Game B'));
      await tester.pump();
      // Collapse A
      await tester.tap(find.text('Game A'));
      await tester.pump();
      // A collapsed, B still open
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('expanded card shows ADMIN with @ prefix', (tester) async {
      await _pump(tester, _twoEntries());
      await tester.tap(find.text('Game A'));
      await tester.pump();
      expect(find.text('@Admin1'), findsOneWidget);
    });

    testWidgets('expanded card shows player results', (tester) async {
      await _pump(tester, _twoEntries());
      await tester.tap(find.text('Game A'));
      await tester.pump();
      expect(find.text('P1'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------

  group('GameHistoryScreen — adversarial', () {
    testWidgets('rapid taps on same card: stable state', (tester) async {
      await _pump(tester, _twoEntries());
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('Game A'));
        await tester.pump();
      }
      // 10 taps (even) → collapsed
      expect(find.byIcon(Icons.expand_less), findsNothing);
    });

    testWidgets('rapid alternating taps on two cards: stable state', (tester) async {
      await _pump(tester, _twoEntries());
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text(i.isEven ? 'Game A' : 'Game B'));
        await tester.pump();
      }
      // 6 taps: A(0,2,4) = 3 taps odd = expanded; B(1,3,5) = 3 taps odd = expanded
      expect(find.byIcon(Icons.expand_less), findsNWidgets(2));
    });

    testWidgets('20-card list: all render without crash', (tester) async {
      final entries = List.generate(
        20,
        (i) => GameHistoryEntry(
          id: 'gh-$i',
          title: 'Game $i',
          description: 'Desc $i',
          viewerPnl: i.isEven ? i.toDouble() : -i.toDouble(),
          securityType: i.isEven ? 'Public' : 'Private',
          isRanked: i.isEven,
          adminName: 'Admin$i',
          envelopePriceUsd: i.toDouble(),
          startedAt: null,
        endedAt: null,
          playerResults: const [],
        ),
      );
      await _pump(tester, entries);
      // At least some cards render (list may not show all without scrolling)
      expect(find.byType(GameHistoryCard), findsWidgets);
    });
  });
}
