import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/widgets/new_order_modal.dart';

void main() {
  group('NewOrderModal', () {
    testWidgets('limit order yields resting with limit price', (tester) async {
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
      expect(r.status, PersonalOrderStatus.resting);
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
  });
}
