import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/cancel_order_command.dart';
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
      expect(find.text('Last Traded Price \$150.00'), findsOneWidget);
      expect(find.text('Bid Ask Midpoint \$150.00'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('new-order-qty')), '1');
      await tester.enterText(find.byKey(const ValueKey('new-order-limit')), '140');
      final submit = find.byKey(const ValueKey('new-order-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('active-order-local_p_me_1')),
        findsOneWidget,
      );
    });

    testWidgets('new order dialog shows bid ask midpoint hyphen when book empty',
        (tester) async {
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
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: data),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-new-order')));
      await tester.pumpAndSettle();
      expect(find.text('Last Traded Price \$10.00'), findsOneWidget);
      expect(find.text('Bid Ask Midpoint -'), findsOneWidget);
    });

    testWidgets(
        'bid ask midpoint notifier tracks order book when trading data updates',
        (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      late GameTradingViewData data;
      data = s.data;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    key: const ValueKey('midpoint-refresh'),
                    onPressed: () {
                      setState(() {
                        data = GameTradingViewData(
                          gameTitle: data.gameTitle,
                          description: data.description,
                          isViewerAdmin: data.isViewerAdmin,
                          currentPlayerId: data.currentPlayerId,
                          isTimed: data.isTimed,
                          tradingTimeRemaining: data.tradingTimeRemaining,
                          deltaCash: data.deltaCash,
                          deltaEnvelopes: data.deltaEnvelopes,
                          orderBookBids: const [],
                          orderBookAsks: const [],
                          marketPrice: data.marketPrice,
                          priceHistory: data.priceHistory,
                          chartSessionElapsed: data.chartSessionElapsed,
                          gameStartedAtUtc: data.gameStartedAtUtc,
                          personalOrders: data.personalOrders,
                        );
                      });
                    },
                    child: const Text('refresh'),
                  ),
                  Expanded(
                    child: TickerMode(
                      enabled: false,
                      child: GameTradingScreen(data: data),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-new-order')));
      await tester.pumpAndSettle();
      expect(find.text('Bid Ask Midpoint \$150.00'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('new-order-close')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('midpoint-refresh')));
      await tester.tap(find.byKey(const ValueKey('midpoint-refresh')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('game-trading-new-order')));
      await tester.pumpAndSettle();
      expect(find.text('Bid Ask Midpoint -'), findsOneWidget);
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

    testWidgets('non-admin sees three-dots menu but not End Game', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      expect(s.data.isViewerAdmin, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: s.data),
          ),
        ),
      );
      // Three-dots menu always visible
      expect(find.byKey(const ValueKey('game-trading-menu')), findsOneWidget);
      // Add-time and End Game are admin-only
      expect(find.byKey(const ValueKey('game-trading-add-time')), findsNothing);
    });

    testWidgets('admin sees three-dots menu and add-time control', (tester) async {
      final s = mockTradingScenarioForGameId('g2');
      expect(s.data.isViewerAdmin, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: s.data),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-menu')), findsOneWidget);
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
      await tester.tap(find.byKey(const ValueKey('game-trading-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Logs'));
      await tester.pumpAndSettle();
      expect(logs, isTrue);
      // Dismiss the logs sheet by tapping the barrier above it.
      await tester.tapAt(const Offset(400, 100));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('game-trading-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('End Game'));
      await tester.pump();
      expect(ended, isTrue);
    });

    testWidgets('drops orders omitted from latest backend snapshot',
        (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      var data = s.data;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    key: const ValueKey('backend-trim'),
                    onPressed: () {
                      setState(() {
                        data = GameTradingViewData(
                          gameTitle: data.gameTitle,
                          description: data.description,
                          isViewerAdmin: data.isViewerAdmin,
                          currentPlayerId: data.currentPlayerId,
                          isTimed: data.isTimed,
                          tradingTimeRemaining: data.tradingTimeRemaining,
                          deltaCash: data.deltaCash,
                          deltaEnvelopes: data.deltaEnvelopes,
                          orderBookBids: data.orderBookBids,
                          orderBookAsks: data.orderBookAsks,
                          marketPrice: data.marketPrice,
                          priceHistory: data.priceHistory,
                          chartSessionElapsed: data.chartSessionElapsed,
                          personalOrders: [data.personalOrders.first],
                          gameStartedAtUtc: data.gameStartedAtUtc,
                        );
                      });
                    },
                    child: const Text('trim'),
                  ),
                  Expanded(
                    child: TickerMode(
                      enabled: false,
                      child: GameTradingScreen(data: data),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('active-order-po_g1_q')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('backend-trim')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('active-order-po_g1_q')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('active-order-po_g1_rest')),
        findsOneWidget,
      );
    });

    testWidgets(
      'cancel command ack timeout reverts button and shows snackbar',
      (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(
              data: s.data,
              submitCancelOrderCommand:
                  ({required String orderId, required int quantityToCancel}) =>
                      Completer<CancelOrderSubmitOutcome>().future,
            ),
          ),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('active-order-po_g1_rest')),
      );
      await tester.tap(find.byKey(const ValueKey('active-order-po_g1_rest')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('active-order-cancel-po_g1_rest')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('partial-cancel-submit')));
      await tester.pump();
      expect(find.text('Cancelling'), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(find.text('Cancelling'), findsNothing);
      expect(find.text('Cancel Order'), findsWidgets);
      expect(
        find.text('Could not create cancellation request'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Cancelling state survives new GameTradingViewData until order cancelled',
      (tester) async {
        final s = mockTradingScenarioForGameId('g1');

        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: TickerMode(
              enabled: false,
              child: _TradingCancelHarness(initialData: s.data),
            ),
          ),
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('active-order-po_g1_rest')),
        );
        await tester.tap(find.byKey(const ValueKey('active-order-po_g1_rest')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('active-order-cancel-po_g1_rest')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('partial-cancel-submit')));
        await tester.pump();
        expect(find.text('Cancelling'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('game-trading-bump-data')));
        await tester.pump();
        expect(find.text('Cancelling'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1900));
        await tester.pumpAndSettle();
        expect(find.text('Cancelled'), findsOneWidget);
      },
    );

    testWidgets(
      'custom cancel submit ack does not run mock worker completion timer',
      (tester) async {
        final s = mockTradingScenarioForGameId('g1');
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: TickerMode(
              enabled: false,
              child: GameTradingScreen(
                data: s.data,
                submitCancelOrderCommand:
                    ({required String orderId, required int quantityToCancel}) async =>
                        CancelOrderSubmitOutcome.fullCommandQueued,
              ),
            ),
          ),
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('active-order-po_g1_rest')),
        );
        await tester.tap(find.byKey(const ValueKey('active-order-po_g1_rest')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('active-order-cancel-po_g1_rest')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('partial-cancel-submit')));
        await tester.pump();
        expect(find.text('Cancelling'), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 1900));
        await tester.pumpAndSettle();
        expect(find.text('Cancelled'), findsNothing);
        expect(find.text('Cancelling'), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------

  group('GameTradingScreen — header', () {
    testWidgets('back button is present', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: s.data, gameId: 'g1'),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-back')), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('three-dots menu is always visible for non-admin', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      expect(s.data.isViewerAdmin, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: s.data),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('game-trading-menu')), findsOneWidget);
    });

    testWidgets('non-admin Show Logs opens logs sheet', (tester) async {
      const logs = [
        TradeLogEntry(
          sellerName: 'Alpha',
          sellerPlayerId: 'p_alpha',
          buyerName: 'Beta',
          buyerPlayerId: 'p_beta',
          quantity: 3,
          price: 149.50,
        ),
        TradeLogEntry(
          sellerName: 'MeSeller',
          sellerPlayerId: 'p1',
          buyerName: 'Gamma',
          buyerPlayerId: 'p_gamma',
          quantity: 1,
          price: 150.00,
        ),
      ];
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
        tradeLogs: logs,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: data),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Logs'));
      await tester.pumpAndSettle();
      expect(find.text('TRANSACTION LOG'), findsOneWidget);
      expect(find.text('SELLER'), findsOneWidget);
      expect(find.text('BUYER'), findsOneWidget);
      expect(find.text('My transactions'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('MeSeller'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.byKey(const ValueKey('trade-logs-list')), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('trade-logs-only-mine-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('MeSeller'), findsOneWidget);
      expect(find.byKey(const ValueKey('trade-logs-list')), findsOneWidget);
    });

    testWidgets(
        'transaction log only-my toggle shows empty when viewer not in any row',
        (tester) async {
      const logs = [
        TradeLogEntry(
          sellerName: 'Alpha',
          sellerPlayerId: 'p_alpha',
          buyerName: 'Beta',
          buyerPlayerId: 'p_beta',
          quantity: 3,
          price: 149.50,
        ),
      ];
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
        tradeLogs: logs,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: data),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Logs'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('trade-logs-only-mine-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching transactions'), findsOneWidget);
      expect(find.byKey(const ValueKey('trade-logs-list')), findsNothing);
    });

    testWidgets('logs sheet shows empty state when no trades', (tester) async {
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
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: data),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Logs'));
      await tester.pumpAndSettle();
      expect(find.text('TRANSACTION LOG'), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
    });

    testWidgets('non-admin menu has Show Logs but not End Game', (tester) async {
      final s = mockTradingScenarioForGameId('g1');
      expect(s.data.isViewerAdmin, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: s.data),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Show Logs'), findsOneWidget);
      expect(find.text('End Game'), findsNothing);
    });

    testWidgets('admin menu has both Show Logs and End Game', (tester) async {
      final s = mockTradingScenarioForGameId('g2');
      expect(s.data.isViewerAdmin, isTrue);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TickerMode(
            enabled: false,
            child: GameTradingScreen(data: s.data),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('game-trading-menu')));
      await tester.pumpAndSettle();
      expect(find.text('Show Logs'), findsOneWidget);
      expect(find.text('End Game'), findsOneWidget);
    });
  });
}

GameTradingViewData _cloneTradingData(GameTradingViewData d) {
  return GameTradingViewData(
    gameTitle: d.gameTitle,
    description: d.description,
    isViewerAdmin: d.isViewerAdmin,
    currentPlayerId: d.currentPlayerId,
    isTimed: d.isTimed,
    tradingTimeRemaining: d.tradingTimeRemaining,
    deltaCash: d.deltaCash,
    deltaEnvelopes: d.deltaEnvelopes,
    orderBookBids: d.orderBookBids,
    orderBookAsks: d.orderBookAsks,
    marketPrice: d.marketPrice,
    priceHistory: d.priceHistory,
    chartSessionElapsed: d.chartSessionElapsed,
    personalOrders: List<PersonalOrder>.from(d.personalOrders),
    gameStartedAtUtc: d.gameStartedAtUtc,
  );
}

class _TradingCancelHarness extends StatefulWidget {
  const _TradingCancelHarness({required this.initialData});

  final GameTradingViewData initialData;

  @override
  State<_TradingCancelHarness> createState() => _TradingCancelHarnessState();
}

class _TradingCancelHarnessState extends State<_TradingCancelHarness> {
  late GameTradingViewData _data;

  @override
  void initState() {
    super.initState();
    _data = _cloneTradingData(widget.initialData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          key: const ValueKey('game-trading-bump-data'),
          onPressed: () => setState(() => _data = _cloneTradingData(_data)),
          child: const Text('bump'),
        ),
        Expanded(
          child: GameTradingScreen(data: _data),
        ),
      ],
    );
  }
}
