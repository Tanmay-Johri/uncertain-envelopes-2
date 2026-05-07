import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/neon_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

DecoratedBox _decoratedBoxOf(WidgetTester tester) {
  // The outer DecoratedBox carries the variant color and glow.
  return tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(NeonButton),
      matching: find.byType(DecoratedBox),
    ).first,
  );
}

void main() {
  group('NeonButton rendering', () {
    testWidgets('renders the label in uppercase', (tester) async {
      await _pump(
        tester,
        NeonButton(label: 'start game', onPressed: () {}),
      );
      expect(find.text('START GAME'), findsOneWidget);
      expect(find.text('start game'), findsNothing);
    });

    testWidgets('empty label renders without crashing', (tester) async {
      await _pump(tester, NeonButton(label: '', onPressed: () {}));
      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('very long label is ellipsized rather than overflowing',
        (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 120,
          child: NeonButton(
            label: 'A very very very long label that does not fit',
            onPressed: () {},
          ),
        ),
      );
      final textWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(NeonButton),
          matching: find.byType(Text),
        ),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('expand=true fills horizontal space', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 400,
          child: NeonButton(label: 'GO', onPressed: () {}),
        ),
      );
      final size = tester.getSize(find.byType(NeonButton));
      expect(size.width, 400);
    });

    testWidgets('expand=false sizes to content', (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 400,
          child: Align(
            alignment: Alignment.centerLeft,
            child:
                NeonButton(label: 'GO', onPressed: () {}, expand: false),
          ),
        ),
      );
      final size = tester.getSize(find.byType(NeonButton));
      expect(size.width, lessThan(400));
    });

    testWidgets('dense=true produces a shorter button', (tester) async {
      await _pump(
        tester,
        NeonButton(label: 'GO', onPressed: () {}, dense: true),
      );
      final size = tester.getSize(find.byType(NeonButton));
      expect(size.height, closeTo(36, 1));
    });

    testWidgets('default height is 48', (tester) async {
      await _pump(tester, NeonButton(label: 'GO', onPressed: () {}));
      final size = tester.getSize(find.byType(NeonButton));
      expect(size.height, closeTo(48, 1));
    });

    testWidgets('leading and trailing icons render', (tester) async {
      await _pump(
        tester,
        NeonButton(
          label: 'NEXT',
          onPressed: () {},
          leadingIcon: Icons.check,
          trailingIcon: Icons.arrow_forward,
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });
  });

  group('NeonButton variants', () {
    testWidgets('primary uses AppColors.primary background', (tester) async {
      await _pump(
        tester,
        NeonButton(label: 'GO', onPressed: () {}),
      );
      final box = _decoratedBoxOf(tester);
      expect((box.decoration as BoxDecoration).color, AppColors.primary);
    });

    testWidgets('destructive uses AppColors.secondary background',
        (tester) async {
      await _pump(
        tester,
        NeonButton(
          label: 'DELETE',
          onPressed: () {},
          variant: NeonButtonVariant.destructive,
        ),
      );
      final box = _decoratedBoxOf(tester);
      expect((box.decoration as BoxDecoration).color, AppColors.secondary);
    });

    testWidgets('outline uses transparent background with outline border',
        (tester) async {
      await _pump(
        tester,
        NeonButton(
          label: 'BACK',
          onPressed: () {},
          variant: NeonButtonVariant.outline,
        ),
      );
      final box = _decoratedBoxOf(tester);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
      expect(decoration.border, isNotNull);
      final borderSide = (decoration.border as Border).top;
      expect(borderSide.color, AppColors.outline);
    });

    testWidgets(
        'outlineDanger uses transparent background with red border',
        (tester) async {
      await _pump(
        tester,
        NeonButton(
          label: 'End Game',
          onPressed: () {},
          variant: NeonButtonVariant.outlineDanger,
        ),
      );
      final box = _decoratedBoxOf(tester);
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, Colors.transparent);
      final borderSide = (decoration.border as Border).top;
      expect(borderSide.color, AppColors.secondary);
      final text = tester.widget<Text>(find.text('END GAME'));
      expect(text.style?.color, AppColors.secondary);
    });

    testWidgets('outlineDanger uses red-tinted ink splash, not theme default',
        (tester) async {
      await _pump(
        tester,
        NeonButton(
          label: 'End Game',
          onPressed: () {},
          variant: NeonButtonVariant.outlineDanger,
        ),
      );
      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(NeonButton),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.splashColor, AppColors.secondary.withValues(alpha: 0.38));
      expect(
        inkWell.highlightColor,
        AppColors.secondary.withValues(alpha: 0.16),
      );
    });

    testWidgets('primary variant has a green glow shadow', (tester) async {
      await _pump(tester, NeonButton(label: 'GO', onPressed: () {}));
      final box = _decoratedBoxOf(tester);
      final shadows = (box.decoration as BoxDecoration).boxShadow;
      expect(shadows, isNotNull);
      expect(shadows!, isNotEmpty);
      expect(shadows.first.color, AppColors.primaryGlow);
    });

    testWidgets('outline variant has no shadow', (tester) async {
      await _pump(
        tester,
        NeonButton(
          label: 'BACK',
          onPressed: () {},
          variant: NeonButtonVariant.outline,
        ),
      );
      final box = _decoratedBoxOf(tester);
      final shadows = (box.decoration as BoxDecoration).boxShadow;
      expect(shadows ?? const [], isEmpty);
    });
  });

  group('NeonButton interaction', () {
    testWidgets('invokes onPressed on tap', (tester) async {
      var tapCount = 0;
      await _pump(
        tester,
        NeonButton(label: 'GO', onPressed: () => tapCount++),
      );
      await tester.tap(find.byType(NeonButton));
      expect(tapCount, 1);
    });

    testWidgets('does nothing when onPressed is null (disabled)',
        (tester) async {
      await _pump(tester, const NeonButton(label: 'GO', onPressed: null));
      // A tap should not throw.
      await tester.tap(find.byType(NeonButton));
      await tester.pump();
      expect(find.byType(NeonButton), findsOneWidget);
    });

    testWidgets('rapid taps fire exactly once per tap (no debounce)',
        (tester) async {
      var tapCount = 0;
      await _pump(
        tester,
        NeonButton(label: 'GO', onPressed: () => tapCount++),
      );
      await tester.tap(find.byType(NeonButton));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byType(NeonButton));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byType(NeonButton));
      expect(tapCount, 3);
    });

    testWidgets('disabled button uses disabled surface colors',
        (tester) async {
      await _pump(tester, const NeonButton(label: 'GO', onPressed: null));
      final box = _decoratedBoxOf(tester);
      expect(
        (box.decoration as BoxDecoration).color,
        AppColors.surfaceContainer,
      );
      final shadows = (box.decoration as BoxDecoration).boxShadow;
      expect(shadows ?? const [], isEmpty);
    });
  });
}
