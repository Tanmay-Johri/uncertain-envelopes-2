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
              onCancel: (_) {},
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('active-orders-empty')), findsOneWidget);
      expect(find.text('No active orders'), findsOneWidget);
    });

    testWidgets('cancel only for resting; confirm removes row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const _OrdersHarness(),
        ),
      );

      expect(find.byKey(const ValueKey('active-order-cancel-r')), findsOneWidget);
      expect(find.byKey(const ValueKey('active-order-cancel-q')), findsNothing);

      final cancelBtn = find.byKey(const ValueKey('active-order-cancel-r'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();
      expect(find.text('Cancel order?'), findsOneWidget);
      // [NeonButton] displays labels uppercased.
      await tester.tap(find.text('CANCEL ORDER'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('active-order-r')), findsNothing);
      expect(find.byKey(const ValueKey('active-order-q')), findsOneWidget);
    });

    testWidgets('dashboard-style: pills, blue chip, first row expanded by default',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const _OrdersHarness(),
        ),
      );
      expect(find.text('Active Orders'), findsOneWidget);
      expect(find.text('BUY LIMIT'), findsOneWidget);
      expect(find.text('in_queue'), findsOneWidget);
      expect(find.textContaining('ID: #'), findsOneWidget);
      await tester.tap(find.text('2 Units'));
      await tester.pumpAndSettle();
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
  var _orders = const [
    PersonalOrder(
      id: 'r',
      side: PersonalOrderSide.buy,
      orderType: PersonalOrderType.limit,
      quantity: 1,
      limitPrice: 10,
      status: PersonalOrderStatus.resting,
    ),
    PersonalOrder(
      id: 'q',
      side: PersonalOrderSide.sell,
      orderType: PersonalOrderType.market,
      quantity: 2,
      limitPrice: null,
      status: PersonalOrderStatus.inQueue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ActiveOrdersWidget(
            orders: _orders,
            onCancel: (id) => setState(() {
              _orders = _orders.where((e) => e.id != id).toList();
            }),
          ),
        ),
      ),
    );
  }
}
