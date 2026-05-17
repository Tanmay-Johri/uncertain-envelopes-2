import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/pnl_calculator.dart';

void main() {
  group('PnlCalculator', () {
    testWidgets('shows projected PnL from market default (g1 math)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PnlCalculator(
              marketPrice: 150,
              deltaCash: 12500,
              deltaEnvelopes: -45,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'+$5,750'), findsOneWidget);
      expect(find.text(r'$150.00'), findsOneWidget);
      expect(find.byKey(const ValueKey('trading-pnl-projected')), findsOneWidget);
    });

    testWidgets('null market price uses default envelope center', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PnlCalculator(
              marketPrice: null,
              deltaCash: 0,
              deltaEnvelopes: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$100.00'), findsOneWidget);
    });

    testWidgets('market-price button snaps assumption and range to market', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PnlCalculator(
              marketPrice: 100,
              deltaCash: 0,
              deltaEnvelopes: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 300 is outside the default ±50% band on 100 (50–150).
      await tester.enterText(
        find.byKey(const ValueKey('trading-pnl-envelope-input')),
        '300',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('trading-pnl-reset')));
      await tester.pump();
      expect(find.text(r'$100.00'), findsOneWidget);
    });

    testWidgets('break-even button sets envelope so projected PnL is zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PnlCalculator(
              marketPrice: 150,
              deltaCash: 12500,
              deltaEnvelopes: -45,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'+$5,750'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('trading-pnl-zero-pnl')));
      await tester.pump();
      final projected = tester.widget<Text>(
        find.byKey(const ValueKey('trading-pnl-projected')),
      );
      expect(projected.data, r'$0');
    });

    testWidgets('break-even button is disabled when deltaEnvelopes is zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PnlCalculator(
              marketPrice: 100,
              deltaCash: 50,
              deltaEnvelopes: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final zeroBtn = tester.widget<IconButton>(
        find.byKey(const ValueKey('trading-pnl-zero-pnl')),
      );
      expect(zeroBtn.onPressed, isNull);
    });

    testWidgets('out-of-range typed value triggers new slider bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PnlCalculator(
              marketPrice: 50,
              deltaCash: 0,
              deltaEnvelopes: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Default for 50 is 20–80 (v≥10 grid); 10 is below min → re-center on 10 → 0–20.
      await tester.enterText(
        find.byKey(const ValueKey('trading-pnl-envelope-input')),
        '10',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final minLabel = tester.widget<Text>(
        find.byKey(const ValueKey('trading-pnl-range-min')),
      );
      expect(minLabel.data, r'$0');
    });
  });
}
