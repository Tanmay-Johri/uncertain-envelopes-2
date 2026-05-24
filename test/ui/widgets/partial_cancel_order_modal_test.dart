import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/partial_cancel_order_modal.dart';

void main() {
  testWidgets('default qty equals initial pending', (tester) async {
    final n = ValueNotifier<int?>(10);
    addTearDown(n.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              PartialCancelOrderModal.show(
                context,
                initialPending: 10,
                pendingListenable: n,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('partial-cancel-qty-field')),
    );
    expect(field.controller?.text, '10');
  });

  testWidgets('minus disabled at 1; plus disabled at max', (tester) async {
    final n = ValueNotifier<int?>(3);
    addTearDown(n.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              PartialCancelOrderModal.show(
                context,
                initialPending: 3,
                pendingListenable: n,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('partial-cancel-qty-field')),
      '1',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final minusInk = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('partial-cancel-minus')),
        matching: find.byType(InkWell),
      ),
    );
    expect(minusInk.onTap, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('partial-cancel-qty-field')),
      '3',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final plusInk = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('partial-cancel-plus')),
        matching: find.byType(InkWell),
      ),
    );
    expect(plusInk.onTap, isNull);
  });

  testWidgets('live pending decrease clamps field', (tester) async {
    final n = ValueNotifier<int?>(10);
    addTearDown(n.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              PartialCancelOrderModal.show(
                context,
                initialPending: 10,
                pendingListenable: n,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      find.text('You have 10 pending units of this order left.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('partial-cancel-qty-field')),
      '9',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    n.value = 5;
    await tester.pump();

    expect(
      find.text('You have 5 pending units of this order left.'),
      findsOneWidget,
    );
    expect(
      find.text('You have 10 pending units of this order left.'),
      findsNothing,
    );

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('partial-cancel-qty-field')),
    );
    expect(field.controller?.text, '5');
  });

  testWidgets('pending drops to zero dismisses dialog', (tester) async {
    final n = ValueNotifier<int?>(2);
    addTearDown(n.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              PartialCancelOrderModal.show(
                context,
                initialPending: 2,
                pendingListenable: n,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('partial-cancel-order-dialog')), findsOneWidget);

    n.value = 0;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('partial-cancel-order-dialog')), findsNothing);
  });

  testWidgets('submit pops selected qty', (tester) async {
    final n = ValueNotifier<int?>(7);
    addTearDown(n.dispose);
    int? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await PartialCancelOrderModal.show(
                  context,
                  initialPending: 7,
                  pendingListenable: n,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('partial-cancel-qty-field')),
      '4',
    );
    await tester.tap(find.byKey(const ValueKey('partial-cancel-submit')));
    await tester.pumpAndSettle();
    expect(result, 4);
  });

  testWidgets('Close pops null', (tester) async {
    final n = ValueNotifier<int?>(7);
    addTearDown(n.dispose);
    int? result = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await PartialCancelOrderModal.show(
                  context,
                  initialPending: 7,
                  pendingListenable: n,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('partial-cancel-close')));
    await tester.pumpAndSettle();
    expect(result, null);
  });
}