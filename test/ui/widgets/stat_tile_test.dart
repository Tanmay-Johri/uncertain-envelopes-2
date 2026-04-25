import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/stat_tile.dart';

void main() {
  group('StatTile', () {
    testWidgets('renders label and value for positive signedValue', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: StatTile(
              label: 'Delta Cash',
              value: r'$99',
              signedValue: 99,
            ),
          ),
        ),
      );
      expect(find.text('Delta Cash'), findsOneWidget);
      expect(find.text(r'$99'), findsOneWidget);
      final border = tester.widget<Container>(find.byType(Container).first);
      final deco = border.decoration! as BoxDecoration;
      expect(deco.border, isA<Border>());
      final b = deco.border as Border;
      expect(b.top.color, AppColors.primary.withValues(alpha: 0.2));
    });

    testWidgets('negative signedValue uses secondary tint on border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: StatTile(
              label: 'Delta Envelopes',
              value: '-3',
              signedValue: -3,
            ),
          ),
        ),
      );
      expect(find.text('Delta Envelopes'), findsOneWidget);
      expect(find.text('-3'), findsOneWidget);
      final border = tester.widget<Container>(find.byType(Container).first);
      final deco = border.decoration! as BoxDecoration;
      final b = deco.border! as Border;
      expect(b.top.color, AppColors.secondary.withValues(alpha: 0.2));
    });

    testWidgets('zero uses outline border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: StatTile(
              label: 'Delta Cash',
              value: r'$0',
              signedValue: 0,
            ),
          ),
        ),
      );
      final border = tester.widget<Container>(find.byType(Container).first);
      final deco = border.decoration! as BoxDecoration;
      final b = deco.border! as Border;
      expect(b.top.color, AppColors.outline);
    });

    testWidgets('long value does not overflow narrow width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              child: StatTile(
                label: 'L',
                value: r'$9,999,999',
                signedValue: 9999999,
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
