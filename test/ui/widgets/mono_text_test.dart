import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/theme/app_typography.dart';
import 'package:uncertain_envelopes_2/ui/widgets/mono_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

TextStyle _styleOf(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style!;
}

void main() {
  group('MonoText rendering', () {
    testWidgets('renders the literal text', (tester) async {
      await _pump(tester, const MonoText('+240.00'));
      expect(find.text('+240.00'), findsOneWidget);
    });

    testWidgets('empty string renders without crashing', (tester) async {
      await _pump(tester, const MonoText(''));
      expect(find.byType(MonoText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('always uses FiraCode family', (tester) async {
      await _pump(tester, const MonoText('42'));
      expect(_styleOf(tester, '42').fontFamily, AppFontFamilies.mono);
    });
  });

  group('MonoText size presets', () {
    testWidgets('small uses monoSmall', (tester) async {
      await _pump(
        tester,
        const MonoText('s', size: MonoTextSize.small),
      );
      expect(_styleOf(tester, 's').fontSize, AppTypography.monoSmall.fontSize);
    });

    testWidgets('medium uses monoMedium (default)', (tester) async {
      await _pump(tester, const MonoText('m'));
      expect(
        _styleOf(tester, 'm').fontSize,
        AppTypography.monoMedium.fontSize,
      );
    });

    testWidgets('large uses monoLarge', (tester) async {
      await _pump(
        tester,
        const MonoText('l', size: MonoTextSize.large),
      );
      expect(_styleOf(tester, 'l').fontSize, AppTypography.monoLarge.fontSize);
    });

    testWidgets('stat uses statValue (24px bold)', (tester) async {
      await _pump(
        tester,
        const MonoText('+\$240', size: MonoTextSize.stat),
      );
      expect(_styleOf(tester, '+\$240').fontSize, 24);
      expect(_styleOf(tester, '+\$240').fontWeight, FontWeight.w700);
    });

    testWidgets('timer uses timerDisplay (48px w/ negative tracking)',
        (tester) async {
      await _pump(
        tester,
        const MonoText('12:34', size: MonoTextSize.timer),
      );
      final style = _styleOf(tester, '12:34');
      expect(style.fontSize, 48);
      expect(style.letterSpacing, isNegative);
    });
  });

  group('MonoText overrides', () {
    testWidgets('custom color overrides base color', (tester) async {
      await _pump(
        tester,
        const MonoText('+240', color: AppColors.primary),
      );
      expect(_styleOf(tester, '+240').color, AppColors.primary);
    });

    testWidgets('custom weight overrides base weight', (tester) async {
      await _pump(
        tester,
        const MonoText('x', fontWeight: FontWeight.w300),
      );
      expect(_styleOf(tester, 'x').fontWeight, FontWeight.w300);
    });

    testWidgets('textAlign is forwarded', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 200,
          child: MonoText('hi', textAlign: TextAlign.end),
        ),
      );
      final text = tester.widget<Text>(find.text('hi'));
      expect(text.textAlign, TextAlign.end);
    });

    testWidgets('overflow is forwarded', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 40,
          child: MonoText(
            'something long that will not fit',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.text('something long that will not fit'),
      );
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom letterSpacing overrides base', (tester) async {
      await _pump(
        tester,
        const MonoText('abc', letterSpacing: 5),
      );
      expect(_styleOf(tester, 'abc').letterSpacing, 5);
    });
  });
}
