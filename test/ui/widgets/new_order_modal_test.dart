import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/providers/view_data/trading_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_view_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/new_order_modal.dart';

void main() {
  group('NewOrderModal', () {
    testWidgets('limit price defaults to market and stepper adds 1.00',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.show(context, marketPrice: 100.0);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final limitFinder = find.byKey(const ValueKey('new-order-limit'));
      expect(
        tester.widget<TextField>(limitFinder).controller!.text,
        '100.00',
      );
      await tester.tap(find.byKey(const ValueKey('new-order-limit-plus')));
      await tester.pump();
      expect(
        tester.widget<TextField>(limitFinder).controller!.text,
        '101.00',
      );
    });

    testWidgets('Last Traded Price tracks listenable while dialog is open',
        (tester) async {
      final live = ValueNotifier<double>(150.0);
      addTearDown(live.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.show(
                      context,
                      marketPrice: 150.0,
                      marketPriceListenable: live,
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Last Traded Price \$150.00'), findsOneWidget);

      live.value = 175.5;
      await tester.pump();
      expect(find.text('Last Traded Price \$175.50'), findsOneWidget);
    });

    testWidgets(
        'stance line updates for buy/sell limit with X and for market orders',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.show(context, marketPrice: 100.0);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '"You are betting that the envelope value will be more than \$100.00"',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('new-order-side-sell')));
      await tester.pump();
      expect(
        find.text(
          '"You are betting that the envelope value will be less than \$100.00"',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('new-order-type-market')));
      await tester.pump();
      expect(
        find.text(
          '"You are betting that the envelope value will decrease"',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('new-order-side-buy')));
      await tester.pump();
      expect(
        find.text(
          '"You are betting that the envelope value will increase"',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('new-order-type-limit')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('new-order-limit')),
        '149.25',
      );
      await tester.pump();
      expect(
        find.text(
          '"You are betting that the envelope value will be more than \$149.25"',
        ),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('new-order-limit')),
        '152.876',
      );
      await tester.pump();
      expect(
        find.text(
          '"You are betting that the envelope value will be more than \$152.876"',
        ),
        findsOneWidget,
      );
    });

    testWidgets('bid ask midpoint shows hyphen when null and updates when set',
        (tester) async {
      final mid = ValueNotifier<double?>(null);
      addTearDown(mid.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.show(
                      context,
                      marketPrice: 100.0,
                      bidAskMidpointListenable: mid,
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Bid Ask Midpoint -'), findsOneWidget);

      mid.value = 123.456;
      await tester.pump();
      expect(find.text('Bid Ask Midpoint \$123.46'), findsOneWidget);

      mid.value = null;
      await tester.pump();
      expect(find.text('Bid Ask Midpoint -'), findsOneWidget);
    });

    testWidgets('limit order yields in_queue with limit price', (tester) async {
      PersonalOrder? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await NewOrderModal.show(context, marketPrice: 150);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('new-order-qty')), '4');
      await tester.enterText(find.byKey(const ValueKey('new-order-limit')), '149.25');
      await tester.tap(find.byKey(const ValueKey('new-order-side-sell')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-order-submit')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      final r = result!;
      expect(r.side, PersonalOrderSide.sell);
      expect(r.orderType, PersonalOrderType.limit);
      expect(r.quantityInitial, 4);
      expect(r.quantityCurrent, 4);
      expect(r.limitPrice, 149.25);
      expect(r.status, PersonalOrderStatus.inQueue);
    });

    testWidgets(
        'defaults buy+limit; unselected market chip is neutral not green',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.show(context, marketPrice: 100);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final green =
          personalOrderStatusChipStyle(PersonalOrderStatus.filled);
      final limit = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('new-order-type-limit')),
          matching: find.byType(DecoratedBox),
        ),
      );
      final market = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('new-order-type-market')),
          matching: find.byType(DecoratedBox),
        ),
      );
      final limitBorder =
          ((limit.decoration as BoxDecoration).border as Border).top.color;
      final marketBorder =
          ((market.decoration as BoxDecoration).border as Border).top.color;
      expect(limitBorder, green.border);
      expect(marketBorder, isNot(green.border));
      expect(
        marketBorder,
        isNot(
          personalOrderStatusChipStyle(PersonalOrderStatus.cancelled).border,
        ),
      );
    });

    testWidgets('type toggles follow side: sell uses red chip palette', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.show(context, marketPrice: 100);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-order-side-sell')));
      await tester.pumpAndSettle();

      final limit = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('new-order-type-limit')),
          matching: find.byType(DecoratedBox),
        ),
      );
      final sellChip =
          personalOrderStatusChipStyle(PersonalOrderStatus.cancelled);
      expect(limit.decoration, isA<BoxDecoration>());
      final d = limit.decoration as BoxDecoration;
      expect(d.border, isA<Border>());
      expect(
        (d.border as Border).top.color,
        sellChip.border,
      );
    });

    testWidgets('market order hides limit field and yields inQueue', (tester) async {
      PersonalOrder? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await NewOrderModal.show(context, marketPrice: 99);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('new-order-type-market')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-order-limit')), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('new-order-qty')), '7');
      await tester.tap(find.byKey(const ValueKey('new-order-submit')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      final r = result!;
      expect(r.orderType, PersonalOrderType.market);
      expect(r.limitPrice, isNull);
      expect(r.status, PersonalOrderStatus.inQueue);
      expect(r.quantityInitial, 7);
      expect(r.quantityCurrent, 7);
    });

    testWidgets('close icon dismisses without result', (tester) async {
      PersonalOrder? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await NewOrderModal.show(context, marketPrice: 50);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-order-close')));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byKey(const ValueKey('new-order-dialog')), findsNothing);
    });

    testWidgets('quantity defaults to 1; stepper bumps value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.show(context, marketPrice: 1);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final fieldFinder = find.byKey(const ValueKey('new-order-qty'));
      expect(tester.widget<TextField>(fieldFinder).controller!.text, '1');
      await tester.tap(find.byKey(const ValueKey('new-order-qty-plus')));
      await tester.pump();
      expect(tester.widget<TextField>(fieldFinder).controller!.text, '2');
      await tester.tap(find.byKey(const ValueKey('new-order-qty-minus')));
      await tester.pump();
      expect(tester.widget<TextField>(fieldFinder).controller!.text, '1');
      await tester.tap(find.byKey(const ValueKey('new-order-qty-minus')));
      await tester.pump();
      expect(tester.widget<TextField>(fieldFinder).controller!.text, '1');
    });

    testWidgets('quantity floors decimals on done', (tester) async {
      PersonalOrder? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await NewOrderModal.show(context, marketPrice: 1);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('new-order-qty')),
        '3.7',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('new-order-qty')),
            )
            .controller!
            .text,
        '3',
      );

      await tester.tap(find.byKey(const ValueKey('new-order-type-market')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-order-submit')));
      await tester.pumpAndSettle();
      expect(result?.quantityInitial, 3);
    });

    testWidgets('invalid qty does not pop', (tester) async {
      PersonalOrder? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    result = await NewOrderModal.show(context, marketPrice: 1);
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('new-order-qty')), '0');
      await tester.enterText(find.byKey(const ValueKey('new-order-limit')), '10');
      await tester.tap(find.byKey(const ValueKey('new-order-submit')));
      await tester.pump();
      expect(result, isNull);
      expect(find.byKey(const ValueKey('new-order-dialog')), findsOneWidget);
    });

    testWidgets('showChoosingGame with empty titles never opens dialog',
        (tester) async {
      late BuildContext navigatorContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                navigatorContext = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final future = NewOrderModal.showChoosingGame(
        navigatorContext,
        gameTitles: const [],
      );
      await tester.pumpAndSettle();
      expect(await future, isNull);
      expect(find.byKey(const ValueKey('new-order-dialog')), findsNothing);
    });

    testWidgets(
        'showChoosingGame sorts games and seeds limit from first title',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.showChoosingGame(
                      context,
                      gameTitles: const ['Zebra', 'Alpha'],
                      marketPriceForGameTitle: (g) =>
                          g == 'Alpha' ? 12.25 : 99.0,
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('new-order-game')), findsOneWidget);
      final limitFinder = find.byKey(const ValueKey('new-order-limit'));
      expect(
        tester.widget<TextField>(limitFinder).controller!.text,
        '12.25',
      );
    });

    testWidgets(
        'showChoosingGame renders bid–ask midpoint from resolver',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    NewOrderModal.showChoosingGame(
                      context,
                      gameTitles: const ['OnlyGame'],
                      marketPriceForGameTitle: (_) => 5,
                      bidAskMidpointForGameTitle: (_) => 7.25,
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bid Ask Midpoint \$7.25'),
        findsOneWidget,
      );
    });

    testWidgets('showChoosingGame submit pops GameScopedNewOrder',
        (tester) async {
      GameScopedNewOrder? popped;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    popped = await NewOrderModal.showChoosingGame(
                      context,
                      gameTitles: const ['OnlyGame'],
                      marketPriceForGameTitle: (_) => 5,
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('new-order-submit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-order-submit')));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.gameTitle, 'OnlyGame');
      expect(popped!.order.id, 'new');
      expect(popped!.order.quantityInitial, 1);
    });

    testWidgets(
      'showChoosingGame with gameIdForTitle seeds limit from live market price',
      (tester) async {
        final d = mockTradingScenarioForGameId('g1').data;
        final at100 = GameTradingViewData(
          gameTitle: d.gameTitle,
          description: d.description,
          isViewerAdmin: d.isViewerAdmin,
          currentPlayerId: d.currentPlayerId,
          isTimed: d.isTimed,
          deltaCash: d.deltaCash,
          deltaEnvelopes: d.deltaEnvelopes,
          orderBookBids: d.orderBookBids,
          orderBookAsks: d.orderBookAsks,
          marketPrice: 100,
          priceHistory: d.priceHistory,
          chartSessionElapsed: d.chartSessionElapsed,
          personalOrders: d.personalOrders,
          tradeLogs: d.tradeLogs,
          gameStartedAtUtc: d.gameStartedAtUtc,
          tradingTimeRemaining: d.tradingTimeRemaining,
          tradingDeadlineUtc: d.tradingDeadlineUtc,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tradingViewDataProvider('game-x').overrideWith(
                (ref) => Future.value(at100),
              ),
            ],
            child: MaterialApp(
              theme: buildAppTheme(),
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return TextButton(
                      onPressed: () {
                        NewOrderModal.showChoosingGame(
                          context,
                          gameTitles: const ['Forex Masters'],
                          gameIdForTitle: (_) => 'game-x',
                        );
                      },
                      child: const Text('open'),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        final limitFinder = find.byKey(const ValueKey('new-order-limit'));
        expect(
          tester.widget<TextField>(limitFinder).controller!.text,
          '100.00',
        );
      },
    );

    testWidgets(
      'showChoosingGame with gameIdForTitle completes initState without crash',
      (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tradingViewDataProvider('game-x').overrideWith(
              (ref) => Future.value(mockTradingScenarioForGameId('g1').data),
            ),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return TextButton(
                    onPressed: () {
                      NewOrderModal.showChoosingGame(
                        context,
                        gameTitles: const ['Forex Masters'],
                        gameIdForTitle: (_) => 'game-x',
                      );
                    },
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-order-dialog')), findsOneWidget);
    });
  });
}
