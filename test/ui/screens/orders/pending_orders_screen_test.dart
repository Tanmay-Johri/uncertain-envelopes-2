import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 3, 12, 0);

  List<PendingOrderListItem> _twoSides() => [
        PendingOrderListItem(
          gameTitle: 'Game A',
          gameDescription: '',
          order: PersonalOrder(
            id: 'buy-1',
            side: PersonalOrderSide.buy,
            orderType: PersonalOrderType.limit,
            quantityInitial: 1,
            quantityCurrent: 1,
            limitPrice: 1,
            status: PersonalOrderStatus.resting,
            createdAt: t0,
          ),
        ),
        PendingOrderListItem(
          gameTitle: 'Game B',
          gameDescription: '',
          order: PersonalOrder(
            id: 'sell-1',
            side: PersonalOrderSide.sell,
            orderType: PersonalOrderType.limit,
            quantityInitial: 2,
            quantityCurrent: 2,
            limitPrice: 2,
            status: PersonalOrderStatus.resting,
            createdAt: t0.add(const Duration(minutes: 1)),
          ),
        ),
      ];

  testWidgets('shows title and opens filter sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: _twoSides(),
          now: () => t0,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('pending-orders-scaffold')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-title')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pending-orders-filter-all')), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('filter Buy leaves only buy card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: _twoSides(),
          now: () => t0,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('pending-order-card-buy-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('pending-orders-filter-buy')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pending-order-card-buy-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsNothing);
    expect(find.text('Game B'), findsNothing);
  });

  testWidgets('empty source shows zero message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: const [],
          now: () => t0,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('pending-orders-empty-msg-zero')),
      findsOneWidget,
    );
    expect(find.text('No pending orders'), findsOneWidget);
  });

  testWidgets(
    'filtered to empty shows filter message while source non-empty',
    (tester) async {
      final onlyBuys = _twoSides().where((e) => e.order.side == PersonalOrderSide.buy).toList();
      expect(onlyBuys.length, 1);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(items: onlyBuys, now: () => t0),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const ValueKey('pending-orders-filter-sell')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('pending-orders-empty-msg-filter')),
        findsOneWidget,
      );
      expect(find.text('No orders for this filter'), findsOneWidget);
    },
  );

  testWidgets('onCancelOrder invoked after nested dialog confirm',
      (tester) async {
    final cancelled = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: [
            PendingOrderListItem(
              gameTitle: 'G',
              gameDescription: '',
              order: PersonalOrder(
                id: 'c1',
                side: PersonalOrderSide.buy,
                orderType: PersonalOrderType.limit,
                quantityInitial: 3,
                quantityCurrent: 3,
                limitPrice: 99,
                status: PersonalOrderStatus.resting,
                createdAt: t0,
              ),
            ),
          ],
          now: () => t0,
          onCancelOrder: cancelled.add,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pending-order-card-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-order-cancel-c1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Cancel Order'),
      ),
    );
    await tester.pumpAndSettle();

    expect(cancelled, ['c1']);
  });

  testWidgets(
    'default mock list renders multiple cards without explicit items',
    (tester) async {
      tester.view.physicalSize = const Size(480, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(now: () => DateTime.utc(2026, 5, 3, 15, 0)),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('pending-orders-scaffold')), findsOneWidget);
      expect(find.text('Forex Masters'), findsOneWidget);
      expect(find.text('Crypto Sim 2024'), findsOneWidget);
    },
  );
}
