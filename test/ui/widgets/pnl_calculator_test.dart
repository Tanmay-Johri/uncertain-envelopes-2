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
      expect(find.byKey(const ValueKey('trading-pnl-projected')), findsOneWidget);
    });

    testWidgets('reset snaps assumption and range to market price', (
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
      expect(find.text(r'$100'), findsWidgets);
    });

    testWidgets('out-of-range typed value triggers new slider bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: PnlCalculator(
              marketPrice: 150,
              deltaCash: 0,
              deltaEnvelopes: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Default range for 150 is 70–230; 10 is outside → re-center on 10 → 5–15.
      await tester.enterText(
        find.byKey(const ValueKey('trading-pnl-envelope-input')),
        '10',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final minLabel = tester.widget<Text>(
        find.byKey(const ValueKey('trading-pnl-range-min')),
      );
      expect(minLabel.data, r'$5');
    });
  });
}
