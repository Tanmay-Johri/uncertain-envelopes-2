import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/widgets/active_orders_widget.dart';
import 'package:uncertain_envelopes_2/ui/widgets/partial_cancel_order_modal.dart';

void main() {
  group('ActiveOrdersWidget', () {
    testWidgets('empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ActiveOrdersWidget(
              orders: const [],
              pendingCancellationOrderIds: const {},
              onCancellationRequested: (_, _) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('active-orders-empty')), findsOneWidget);
      expect(find.text('No active orders'), findsOneWidget);
    });

    testWidgets('active only toggle hides closed/cancelled; keeps newest-first',
        (tester) async {
      final tNew = DateTime.utc(2026, 5, 17, 22);
      final tMid = DateTime.utc(2026, 5, 17, 20);
      final tOld = DateTime.utc(2026, 5, 17, 18);
      final orders = [
        PersonalOrder(
          id: 'closed-new',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 1,
          quantityCurrent: 0,
          limitPrice: 103,
          status: PersonalOrderStatus.filled,
          createdAt: tNew,
        ),
        PersonalOrder(
          id: 'rest-mid',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 2,
          quantityCurrent: 2,
          limitPrice: 99,
          status: PersonalOrderStatus.resting,
          createdAt: tMid,
        ),
        PersonalOrder(
          id: 'q-old',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 1,
          quantityCurrent: 1,
          limitPrice: 4.01,
          status: PersonalOrderStatus.inQueue,
          createdAt: tOld,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ActiveOrdersWidget(
              orders: orders,
              pendingCancellationOrderIds: const {},
              onCancellationRequested: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('order_closed'), findsOneWidget);
      expect(find.text('order_resting'), findsOneWidget);
      expect(find.text('in_queue'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('active-orders-active-only-toggle')),
      );
      await tester.pumpAndSettle();

      expect(find.text('order_closed'), findsNothing);
      expect(find.text('order_resting'), findsOneWidget);
      expect(find.text('in_queue'), findsOneWidget);
      // Newest among pipeline-active is resting (tMid > tOld); first card expanded.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('active-order-rest-mid')),
          matching: find.byType(AnimatedRotation),
        ),
        findsOneWidget,
      );
      final rot = tester.widget<AnimatedRotation>(
        find.descendant(
          of: find.byKey(const ValueKey('active-order-rest-mid')),
          matching: find.byType(AnimatedRotation),
        ),
      );
      expect(rot.turns, 0.5);
    });

    testWidgets('active only with no pipeline orders shows empty state',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ActiveOrdersWidget(
              orders: [
                PersonalOrder(
                  id: 'x',
                  side: PersonalOrderSide.buy,
                  orderType: PersonalOrderType.limit,
                  quantityInitial: 1,
                  quantityCurrent: 0,
                  limitPrice: 1,
                  status: PersonalOrderStatus.filled,
                  createdAt: DateTime.utc(2026, 1, 1),
                ),
              ],
              pendingCancellationOrderIds: const {},
              onCancellationRequested: (_, _) {},
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('active-orders-active-only-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('active-orders-empty')), findsOneWidget);
    });

    testWidgets(
        'in_queue order has cancel button disabled (backend resting-only)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const _OrdersHarness(),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('active-order-q')),
      );
      await tester.tap(find.byKey(const ValueKey('active-order-q')));
      await tester.pumpAndSettle();

      final btn = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('active-order-cancel-q')),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets(
        'Close dismisses partial-cancel modal; submit starts cancel then row becomes cancelled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const _OrdersHarness(),
        ),
      );

      await tester.tap(find.textContaining('1 units @'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('active-order-cancel-r')));
      await tester.tap(find.byKey(const ValueKey('active-order-cancel-r')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('partial-cancel-order-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('partial-cancel-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('partial-cancel-order-dialog')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('active-order-cancel-r')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('partial-cancel-submit')));
      await tester.pump();
      expect(find.text('Cancelling'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('order_resting'), findsNothing);
      expect(find.byKey(const ValueKey('active-order-r')), findsOneWidget);
      expect(find.byKey(const ValueKey('active-order-q')), findsOneWidget);
    });

    testWidgets('dashboard-style: pills, chip, PRD detail lines', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const _OrdersHarness(),
        ),
      );
      expect(find.text('Active Orders'), findsOneWidget);
      expect(find.text('BUY LIMIT'), findsOneWidget);
      expect(find.text('order_resting'), findsOneWidget);
      expect(find.textContaining('1 units @'), findsOneWidget);
      expect(find.textContaining('2 units @'), findsOneWidget);
      expect(find.textContaining('ID: #'), findsNothing);
      expect(find.text('in_queue'), findsOneWidget);
      await tester.tap(find.textContaining('1 units @'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Current Qty: 1'), findsOneWidget);
      expect(find.textContaining('Initial Qty: 1'), findsOneWidget);
      expect(find.textContaining('Limit price:'), findsWidgets);
      expect(find.textContaining('Initial Qty:'), findsNWidgets(2));
    });
  });
}

class _OrdersHarness extends StatefulWidget {
  const _OrdersHarness();

  @override
  State<_OrdersHarness> createState() => _OrdersHarnessState();
}

class _OrdersHarnessState extends State<_OrdersHarness> {
  var _orders = [
    PersonalOrder(
      id: 'r',
      side: PersonalOrderSide.buy,
      orderType: PersonalOrderType.limit,
      quantityInitial: 1,
      quantityCurrent: 1,
      limitPrice: 10,
      status: PersonalOrderStatus.resting,
      createdAt: DateTime.utc(2026, 4, 26, 16, 5),
    ),
    PersonalOrder(
      id: 'q',
      side: PersonalOrderSide.sell,
      orderType: PersonalOrderType.market,
      quantityInitial: 2,
      quantityCurrent: 2,
      limitPrice: null,
      status: PersonalOrderStatus.inQueue,
      createdAt: DateTime.utc(2026, 4, 26, 18, 33),
    ),
  ];

  final Set<String> _pending = {};

  Future<void> _onCancellationRequested(
    BuildContext context,
    PersonalOrder o,
  ) async {
    final notifier = ValueNotifier<int?>(o.quantityCurrent);
    try {
      final qty = await PartialCancelOrderModal.show(
        context,
        initialPending: o.quantityCurrent,
        pendingListenable: notifier,
      );
      if (!mounted || qty == null) return;
      setState(() => _pending.add(o.id));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _pending.remove(o.id);
        _orders = [
          for (final x in _orders)
            if (x.id == o.id)
              x.copyWith(status: PersonalOrderStatus.cancelled)
            else
              x,
        ];
      });
    } finally {
      notifier.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ActiveOrdersWidget(
            orders: _orders,
            pendingCancellationOrderIds: _pending,
            onCancellationRequested: (ctx, o) {
              unawaited(_onCancellationRequested(ctx, o));
            },
          ),
        ),
      ),
    );
  }
}
