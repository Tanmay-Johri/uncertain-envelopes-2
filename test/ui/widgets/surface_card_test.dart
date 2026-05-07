import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_spacing.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/surface_card.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

DecoratedBox _outerDecoratedBox(WidgetTester tester) {
  return tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(SurfaceCard),
      matching: find.byType(DecoratedBox),
    ).first,
  );
}

void main() {
  group('SurfaceCard', () {
    testWidgets('renders its child', (tester) async {
      await _pump(
        tester,
        const SurfaceCard(child: Text('hello card')),
      );
      expect(find.text('hello card'), findsOneWidget);
    });

    testWidgets('default background is AppColors.surfaceContainer',
        (tester) async {
      await _pump(tester, const SurfaceCard(child: Text('x')));
      final decoration =
          _outerDecoratedBox(tester).decoration as BoxDecoration;
      expect(decoration.color, AppColors.surfaceContainer);
    });

    testWidgets('custom background is respected', (tester) async {
      await _pump(
        tester,
        const SurfaceCard(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Text('x'),
        ),
      );
      final decoration =
          _outerDecoratedBox(tester).decoration as BoxDecoration;
      expect(decoration.color, AppColors.surfaceContainerLow);
    });

    testWidgets('default border is ghost outline', (tester) async {
      await _pump(tester, const SurfaceCard(child: Text('x')));
      final decoration =
          _outerDecoratedBox(tester).decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.color, AppColors.outline);
    });

    testWidgets('border=false removes the border', (tester) async {
      await _pump(
        tester,
        const SurfaceCard(border: false, child: Text('x')),
      );
      final decoration =
          _outerDecoratedBox(tester).decoration as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('default radius is AppRadius.md', (tester) async {
      await _pump(tester, const SurfaceCard(child: Text('x')));
      final decoration =
          _outerDecoratedBox(tester).decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;
      expect(radius.topLeft.x, AppRadius.md);
    });

    testWidgets('custom radius is respected', (tester) async {
      await _pump(
        tester,
        const SurfaceCard(radius: AppRadius.xl, child: Text('x')),
      );
      final decoration =
          _outerDecoratedBox(tester).decoration as BoxDecoration;
      final radius = decoration.borderRadius as BorderRadius;
      expect(radius.topLeft.x, AppRadius.xl);
    });

    testWidgets('default padding is cardPadding (16)', (tester) async {
      await _pump(tester, const SurfaceCard(child: SizedBox.shrink()));
      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(SurfaceCard),
          matching: find.byType(Padding),
        ).first,
      );
      expect(
        padding.padding,
        const EdgeInsets.all(AppSpacing.cardPadding),
      );
    });

    testWidgets('onTap triggers when tapped', (tester) async {
      var tapCount = 0;
      await _pump(
        tester,
        SurfaceCard(
          onTap: () => tapCount++,
          child: const Text('tap me'),
        ),
      );
      await tester.tap(find.byType(SurfaceCard));
      await tester.pumpAndSettle();
      expect(tapCount, 1);
    });

    testWidgets('without onTap there is no InkWell (non-interactive)',
        (tester) async {
      await _pump(tester, const SurfaceCard(child: Text('x')));
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('with onTap there is an InkWell (interactive)',
        (tester) async {
      await _pump(
        tester,
        SurfaceCard(onTap: () {}, child: const Text('x')),
      );
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('renders deeply nested children without overflow',
        (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 300,
          child: SurfaceCard(
            child: Column(
              children: [
                Text('line 1'),
                Text('line 2'),
                Text('line 3'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('line 1'), findsOneWidget);
      expect(find.text('line 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
