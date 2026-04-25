import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/order_book_row.dart';

void main() {
  group('OrderBookRow', () {
    testWidgets('bid row shows quantity and price with primary tint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookRow(
              side: OrderBookSide.bid,
              quantity: 50,
              price: 149.5,
              depth: 0.8,
            ),
          ),
        ),
      );
      expect(find.text('50'), findsOneWidget);
      expect(find.text(r'$149.50'), findsOneWidget);

      final priceText = tester.widget<Text>(find.text(r'$149.50'));
      expect(priceText.style?.color, AppColors.primary);
    });

    testWidgets('ask row shows price with secondary tint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookRow(
              side: OrderBookSide.ask,
              quantity: 10,
              price: 150.5,
              depth: 0.2,
            ),
          ),
        ),
      );
      expect(find.text('10'), findsOneWidget);
      expect(find.text(r'$150.50'), findsOneWidget);
      final priceText = tester.widget<Text>(find.text(r'$150.50'));
      expect(priceText.style?.color, AppColors.secondary);
    });

    testWidgets('onTap is wired', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookRow(
              side: OrderBookSide.bid,
              quantity: 1,
              price: 1,
              depth: 0.5,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
    });

    testWidgets('depth outside 0–1 is clamped without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookRow(
              side: OrderBookSide.bid,
              quantity: 1,
              price: 1,
              depth: 99,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow width does not overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: SizedBox(
              width: 80,
              child: OrderBookRow(
                side: OrderBookSide.bid,
                quantity: 999999,
                price: 1234567.89,
                depth: 0.5,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
