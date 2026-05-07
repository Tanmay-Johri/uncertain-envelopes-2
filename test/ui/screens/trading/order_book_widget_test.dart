import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/order_book_widget.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_view_data.dart';

void main() {
  group('OrderBookWidget', () {
    testWidgets('shows title and column headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookWidget(
              bids: const [
                OrderBookLevel(price: 1, quantity: 1),
              ],
              asks: const [],
            ),
          ),
        ),
      );
      expect(find.text('Order Book'), findsOneWidget);
      expect(find.text('Qty'), findsNWidgets(2));
      expect(find.text('Bid'), findsOneWidget);
      expect(find.text('Ask'), findsOneWidget);
    });

    testWidgets('renders bid and ask prices from levels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookWidget(
              bids: const [
                OrderBookLevel(price: 149.5, quantity: 50),
              ],
              asks: const [
                OrderBookLevel(price: 150.5, quantity: 10),
              ],
            ),
          ),
        ),
      );
      expect(find.text(r'$149.50'), findsOneWidget);
      expect(find.text(r'$150.50'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('empty sides show headers only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookWidget(
              bids: const [],
              asks: const [],
            ),
          ),
        ),
      );
      expect(find.text('Order Book'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('many rows scroll without overflow exception', (tester) async {
      final bids = List<OrderBookLevel>.generate(
        40,
        (i) => OrderBookLevel(price: 100 - i * 0.01, quantity: i + 1),
      );
      final asks = List<OrderBookLevel>.generate(
        40,
        (i) => OrderBookLevel(price: 101 + i * 0.01, quantity: i + 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: OrderBookWidget(
              bids: bids,
              asks: asks,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -120));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
