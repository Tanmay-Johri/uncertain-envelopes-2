import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/game_trading_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_view_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/countdown_timer.dart';

void main() {
  group('GameTradingScreen', () {
    testWidgets('renders scaffold, title, chart, book, and active orders',
        (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameTradingScreen(data: s.data),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-scaffold')), findsOneWidget);
      expect(find.text('TRADING WINDOW'), findsOneWidget);
      expect(find.text('Forex Masters'), findsWidgets);
      expect(find.byKey(const ValueKey('trading-stat-delta-cash')), findsOneWidget);
      expect(find.text(r'+$12,500'), findsOneWidget);
      expect(find.byKey(const ValueKey('trading-orderbook-section')), findsOneWidget);
      expect(find.text('Order Book'), findsOneWidget);
      expect(find.text(r'$149.50'), findsOneWidget);
      expect(find.byKey(const ValueKey('trading-pnl-section')), findsOneWidget);
      expect(find.text(r'+$5,750'), findsOneWidget);
      expect(find.byKey(const ValueKey('trading-chart-section')), findsOneWidget);
      expect(find.text('Market Price'), findsOneWidget);
      // Market price line and PnL envelope default both use market (150.00).
      expect(find.text(r'$150.00'), findsNWidgets(2));
      expect(find.text('0'), findsWidgets);
      expect(find.text('Minutes since game start'), findsOneWidget);
      expect(find.text('Active Orders'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('active-order-po_g1_rest')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('game-trading-new-order')), findsOneWidget);
    });

    testWidgets('PnL is above chart; chart is above order book', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameTradingScreen(data: s.data),
        ),
      );
      final pnlTop = tester.getRect(
        find.byKey(const ValueKey('trading-pnl-section')),
      ).top;
      final chartTop = tester.getRect(
        find.byKey(const ValueKey('trading-chart-section')),
      ).top;
      final bookTop = tester.getRect(
        find.byKey(const ValueKey('trading-orderbook-section')),
      ).top;
      expect(pnlTop, lessThan(chartTop));
      expect(chartTop, lessThan(bookTop));
    });

    testWidgets('active orders section is below order book', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameTradingScreen(data: s.data),
        ),
      );
      final bookTop = tester.getRect(
        find.byKey(const ValueKey('trading-orderbook-section')),
      ).top;
      final activeTop = tester.getRect(
        find.byKey(const ValueKey('trading-active-orders-section')),
      ).top;
      expect(bookTop, lessThan(activeTop));
    });

    testWidgets('create new order appends a row', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: s.data),
          ),
        ),
      );
      final newOrder = find.byKey(const ValueKey('game-trading-new-order'));
      await tester.ensureVisible(newOrder);
      await tester.tap(newOrder);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('new-order-qty')), '1');
      await tester.enterText(find.byKey(const ValueKey('new-order-limit')), '140');
      await tester.tap(find.byKey(const ValueKey('new-order-submit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('active-order-local_p_me_1')),
        findsOneWidget,
      );
    });

    testWidgets('g1 shows live countdown when timed', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameTradingScreen(data: s.data),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-countdown')), findsOneWidget);
      expect(find.byType(CountdownTimer), findsOneWidget);
      expect(find.text('60:00'), findsOneWidget);
    });

    testWidgets('non-admin does not show admin overflow menu', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      expect(s.data.isViewerAdmin, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameTradingScreen(data: s.data),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-admin-menu')), findsNothing);
      expect(find.byKey(const ValueKey('game-trading-add-time')), findsNothing);
    });

    testWidgets('admin sees overflow menu and add-time control', (tester) async {
      final s = mockTradingScenarioForGameId('g2');
      expect(s.data.isViewerAdmin, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameTradingScreen(data: s.data),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-admin-menu')), findsOneWidget);
      expect(find.byKey(const ValueKey('game-trading-add-time')), findsOneWidget);
    });

    testWidgets('untimed mock hides countdown', (tester) async {
      const data = GameTradingViewData(
        gameTitle: 'T',
        description: 'd',
        isViewerAdmin: false,
        currentPlayerId: 'p1',
        isTimed: false,
        tradingTimeRemaining: null,
        deltaCash: 0,
        deltaEnvelopes: 0,
        orderBookBids: [],
        orderBookAsks: [],
        marketPrice: 10,
        priceHistory: [],
        chartSessionElapsed: Duration.zero,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: GameTradingScreen(data: data),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-countdown')), findsNothing);
      expect(find.byType(CountdownTimer), findsNothing);
    });

    testWidgets('admin menu selections invoke callbacks', (tester) async {
      var logs = false;
      var ended = false;
      final s = mockTradingScenarioForGameId('g2');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          // Stops the market-price pulsing dot’s repeat animation so
          // pumpAndSettle can finish (otherwise it never idles).
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(
              data: s.data,
              onShowLogs: () => logs = true,
              onEndGameFromMenu: () => ended = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-admin-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Logs'));
      await tester.pump();
      expect(logs, isTrue);

      await tester.tap(find.byKey(const ValueKey('game-trading-admin-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End Game'));
      await tester.pump();
      expect(ended, isTrue);
    });
  });
}
