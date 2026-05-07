import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/widgets/active_orders_widget.dart';

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

    testWidgets(
        'in_queue order uses same cancel flow as resting',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const _OrdersHarness(),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('active-order-cancel-q')),
      );
      await tester.tap(find.byKey(const ValueKey('active-order-cancel-q')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Cancelling'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Back dismisses dialog; resting confirm starts cancel then row becomes cancelled',
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
      expect(
        find.text(
          'Are you sure you want to send a cancellation request?',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Are you sure you want to send a cancellation request?',
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('active-order-cancel-r')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
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

  void _onCancellationRequested(BuildContext context, String id) {
    setState(() => _pending.add(id));
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() {
        _pending.remove(id);
        _orders = [
          for (final o in _orders)
            if (o.id == id)
              o.copyWith(status: PersonalOrderStatus.cancelled)
            else
              o,
        ];
      });
    });
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
            onCancellationRequested: _onCancellationRequested,
          ),
        ),
      ),
    );
  }
}
