import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/pending_order_card.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 5, 3, 15, 0);

  Future<void> pumpCard(
    WidgetTester tester,
    PendingOrderListItem item, {
    ValueChanged<String>? onCancel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PendingOrderCard(
              gameTitle: item.gameTitle,
              gameDescription: item.gameDescription,
              order: item.order,
              onCancelRequested: onCancel,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  PendingOrderListItem restingSell() => PendingOrderListItem(
        gameId: 'g-crypto',
        gameTitle: 'Crypto Sim',
        gameDescription:
            'Beginner simulation. Market volatility is currently high.',
        order: PersonalOrder(
          id: '88293-A',
          side: PersonalOrderSide.sell,
          orderType: PersonalOrderType.limit,
          quantityInitial: 500,
          quantityCurrent: 500,
          limitPrice: 0.45,
          status: PersonalOrderStatus.resting,
          createdAt: fixedNow.subtract(const Duration(minutes: 2)),
        ),
      );

  testWidgets(
    'expanded body shows description, trading-style detail rows, cancel',
    (tester) async {
      await pumpCard(tester, restingSell());
      expect(find.textContaining('Qty:'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pending-order-card-88293-A')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Beginner simulation. Market volatility is currently high.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('Initial Qty: 500'), findsOneWidget);
      expect(find.textContaining('Current Qty: 500'), findsOneWidget);
      expect(find.textContaining(r'Limit price: $0.45'), findsOneWidget);
      expect(find.textContaining('Order status: order_resting'), findsOneWidget);
      expect(find.textContaining('Type: sell limit'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
    });

  testWidgets(
    'sell headline price uses red secondary; buy uses primary green',
    (tester) async {
      final sell = restingSell();
      await pumpCard(tester, sell);
      final priceSell = tester.widget<Text>(find.text(r'$0.45'));
      expect(priceSell.style?.color, AppColors.secondary);

      final buy = PendingOrderListItem(
        gameId: 'g-fx',
        gameTitle: 'Fx',
        gameDescription: 'd',
        order: PersonalOrder(
          id: 'b',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 10,
          quantityCurrent: 10,
          limitPrice: 150,
          status: PersonalOrderStatus.resting,
          createdAt: fixedNow,
        ),
      );
      await pumpCard(tester, buy);
      final priceBuy = tester.widget<Text>(find.text(r'$150.00'));
      expect(priceBuy.style?.color, AppColors.primary);
    },
  );

  testWidgets('market order shows em dash headline price', (tester) async {
    final m = PendingOrderListItem(
      gameId: 'g-mkt',
      gameTitle: 'MKT',
      gameDescription: '',
      order: PersonalOrder(
        id: 'mkt1',
        side: PersonalOrderSide.buy,
        orderType: PersonalOrderType.market,
        quantityInitial: 5,
        quantityCurrent: 5,
        limitPrice: null,
        status: PersonalOrderStatus.inQueue,
        createdAt: fixedNow,
      ),
    );
    await pumpCard(tester, m);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets(
      'expanded market order shows dash limit row and buy market type',
      (tester) async {
    final m = PendingOrderListItem(
      gameId: 'g-mkt',
      gameTitle: 'MKT',
      gameDescription: 'Desc',
      order: PersonalOrder(
        id: 'mkt1',
        side: PersonalOrderSide.buy,
        orderType: PersonalOrderType.market,
        quantityInitial: 5,
        quantityCurrent: 5,
        limitPrice: null,
        status: PersonalOrderStatus.inQueue,
        createdAt: fixedNow,
      ),
    );
    await pumpCard(tester, m);
    await tester.tap(find.byKey(const ValueKey('pending-order-card-mkt1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Limit price: —'), findsOneWidget);
    expect(find.textContaining('Type: buy market'), findsOneWidget);
    expect(find.textContaining('Order status: in_queue'), findsOneWidget);
  });

  testWidgets('cancel confirm calls callback once', (tester) async {
    final hits = <String>[];
    await pumpCard(tester, restingSell(), onCancel: hits.add);

    await tester.tap(find.byKey(const ValueKey('pending-order-card-88293-A')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pending-order-cancel-88293-A')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Cancel'),
      ),
    );
    await tester.pumpAndSettle();

    expect(hits, ['88293-A']);
  });

  testWidgets('filled order shows disabled cancel button', (tester) async {
    final filled = PendingOrderListItem(
      gameId: 'g-done',
      gameTitle: 'Done',
      gameDescription: 'x',
      order: PersonalOrder(
        id: 'done',
        side: PersonalOrderSide.buy,
        orderType: PersonalOrderType.limit,
        quantityInitial: 1,
        quantityCurrent: 0,
        limitPrice: 10,
        status: PersonalOrderStatus.filled,
        createdAt: fixedNow,
      ),
    );
    await pumpCard(tester, filled);

    await tester.tap(find.byKey(const ValueKey('pending-order-card-done')));
    await tester.pumpAndSettle();

    final btn = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('pending-order-cancel-done')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('rapid header taps toggle expansion without crashing',
      (tester) async {
    await pumpCard(tester, restingSell());
    final header = find.byKey(const ValueKey('pending-order-card-88293-A'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(header);
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
