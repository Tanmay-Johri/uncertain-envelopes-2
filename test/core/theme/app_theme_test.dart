import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_spacing.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/theme/app_typography.dart';

void main() {
  group('AppColors', () {
    test('primary green matches design spec #40f320', () {
      expect(AppColors.primary, const Color(0xFF40F320));
    });

    test('secondary red matches design spec #ff3b30', () {
      expect(AppColors.secondary, const Color(0xFFFF3B30));
    });

    test('background matches design spec #1f1f1f', () {
      expect(AppColors.background, const Color(0xFF1F1F1F));
    });

    test('surface container matches design spec #2a2a2a', () {
      expect(AppColors.surfaceContainer, const Color(0xFF2A2A2A));
    });

    test('surface container low matches design spec #1e1e1e', () {
      expect(AppColors.surfaceContainerLow, const Color(0xFF1E1E1E));
    });

    test('outline is white at 10% opacity', () {
      expect(AppColors.outline, const Color(0x1AFFFFFF));
    });

    test('outline subtle is white at 5% opacity', () {
      expect(AppColors.outlineSubtle, const Color(0x0DFFFFFF));
    });

    test('surface hierarchy has ascending luminosity', () {
      final low = AppColors.surfaceContainerLow.computeLuminance();
      final mid = AppColors.surfaceContainer.computeLuminance();
      final high = AppColors.surfaceContainerHigh.computeLuminance();
      expect(mid, greaterThan(low));
      expect(high, greaterThan(mid));
    });
  });

  group('AppSpacing', () {
    test('spacing scale uses 4px base', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 12);
      expect(AppSpacing.lg, 16);
      expect(AppSpacing.xl, 20);
      expect(AppSpacing.xxl, 24);
      expect(AppSpacing.xxxl, 32);
    });

    test('semantic aliases reference correct values', () {
      expect(AppSpacing.sectionGap, AppSpacing.xxl);
      expect(AppSpacing.cardPadding, AppSpacing.lg);
      expect(AppSpacing.inputPadding, AppSpacing.md);
      expect(AppSpacing.labelGap, AppSpacing.sm);
    });
  });

  group('AppRadius', () {
    test('radius scale matches design spec', () {
      expect(AppRadius.sm, 4);
      expect(AppRadius.md, 8);
      expect(AppRadius.lg, 12);
      expect(AppRadius.xl, 16);
      expect(AppRadius.full, 9999);
    });
  });

  group('AppFontFamilies', () {
    test('display family is Epilogue', () {
      expect(AppFontFamilies.display, 'Epilogue');
    });

    test('body family is SpaceGrotesk', () {
      expect(AppFontFamilies.body, 'SpaceGrotesk');
    });

    test('mono family is FiraCode', () {
      expect(AppFontFamilies.mono, 'FiraCode');
    });
  });

  group('AppTypography', () {
    test('heroHeadline is 30px bold Epilogue', () {
      expect(AppTypography.heroHeadline.fontSize, 30);
      expect(AppTypography.heroHeadline.fontWeight, FontWeight.w700);
      expect(AppTypography.heroHeadline.fontFamily, AppFontFamilies.display);
    });

    test('sectionHeader is 24px bold Epilogue', () {
      expect(AppTypography.sectionHeader.fontSize, 24);
      expect(AppTypography.sectionHeader.fontWeight, FontWeight.w700);
      expect(AppTypography.sectionHeader.fontFamily, AppFontFamilies.display);
    });

    test('bodyMedium is 14px regular SpaceGrotesk', () {
      expect(AppTypography.bodyMedium.fontSize, 14);
      expect(AppTypography.bodyMedium.fontWeight, FontWeight.w400);
      expect(AppTypography.bodyMedium.fontFamily, AppFontFamilies.body);
    });

    test('microLabel is 10px bold with tracking', () {
      expect(AppTypography.microLabel.fontSize, 10);
      expect(AppTypography.microLabel.fontWeight, FontWeight.w700);
      expect(AppTypography.microLabel.letterSpacing, isNotNull);
      expect(AppTypography.microLabel.letterSpacing!, greaterThan(0));
    });

    test('monoLarge is 16px medium FiraCode', () {
      expect(AppTypography.monoLarge.fontSize, 16);
      expect(AppTypography.monoLarge.fontWeight, FontWeight.w500);
      expect(AppTypography.monoLarge.fontFamily, AppFontFamilies.mono);
    });

    test('statValue is 24px bold FiraCode', () {
      expect(AppTypography.statValue.fontSize, 24);
      expect(AppTypography.statValue.fontWeight, FontWeight.w700);
      expect(AppTypography.statValue.fontFamily, AppFontFamilies.mono);
    });

    test('timerDisplay is 48px bold with negative tracking', () {
      expect(AppTypography.timerDisplay.fontSize, 48);
      expect(AppTypography.timerDisplay.fontWeight, FontWeight.w700);
      expect(AppTypography.timerDisplay.letterSpacing, isNegative);
    });

    test('brandHeader uses primary color with wide tracking', () {
      expect(AppTypography.brandHeader.color, AppColors.primary);
      expect(AppTypography.brandHeader.letterSpacing, greaterThanOrEqualTo(3));
    });

    test('buttonPrimary uses background color (dark on primary)', () {
      expect(AppTypography.buttonPrimary.color, AppColors.background);
      expect(AppTypography.buttonPrimary.fontWeight, FontWeight.w700);
    });

    test('all styles use one of the three font families', () {
      final validFamilies = {
        AppFontFamilies.display,
        AppFontFamilies.body,
        AppFontFamilies.mono,
      };
      final styles = [
        AppTypography.heroHeadline,
        AppTypography.sectionHeader,
        AppTypography.screenTitle,
        AppTypography.bodyLarge,
        AppTypography.bodyMedium,
        AppTypography.bodySmall,
        AppTypography.label,
        AppTypography.microLabel,
        AppTypography.monoLarge,
        AppTypography.monoMedium,
        AppTypography.monoSmall,
        AppTypography.statValue,
        AppTypography.timerDisplay,
        AppTypography.brandHeader,
        AppTypography.buttonPrimary,
        AppTypography.buttonSecondary,
      ];
      for (final style in styles) {
        expect(
          validFamilies.contains(style.fontFamily),
          isTrue,
          reason: '${style.fontFamily} is not in $validFamilies',
        );
      }
    });
  });

  group('buildAppTheme', () {
    late ThemeData theme;

    setUp(() {
      theme = buildAppTheme();
    });

    test('uses dark brightness', () {
      expect(theme.brightness, Brightness.dark);
    });

    test('uses Material 3', () {
      expect(theme.useMaterial3, true);
    });

    test('scaffold background matches AppColors.background', () {
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });

    test('colorScheme primary matches AppColors.primary', () {
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('colorScheme secondary matches AppColors.secondary', () {
      expect(theme.colorScheme.secondary, AppColors.secondary);
    });

    test('colorScheme onPrimary is dark (for contrast on green)', () {
      expect(theme.colorScheme.onPrimary, AppColors.background);
    });

    test('appBar is 95% opaque with centered title', () {
      expect(theme.appBarTheme.centerTitle, true);
      expect(theme.appBarTheme.elevation, 0);
      final bgColor = theme.appBarTheme.backgroundColor!;
      expect(bgColor.a, closeTo(242 / 255, 0.01));
    });

    test('card has zero elevation and ghost border', () {
      expect(theme.cardTheme.elevation, 0);
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.outline);
    });

    test('input decoration uses correct fill and border colors', () {
      expect(
        theme.inputDecorationTheme.fillColor,
        AppColors.surfaceContainerLow,
      );
      final focusBorder =
          theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;
      expect(focusBorder.borderSide.color, AppColors.primary);
    });

    test('elevated button uses primary green with dark text', () {
      final style = theme.elevatedButtonTheme.style!;
      final bgColor = style.backgroundColor!.resolve({});
      expect(bgColor, AppColors.primary);
      final fgColor = style.foregroundColor!.resolve({});
      expect(fgColor, AppColors.background);
    });

    test('default text theme body uses SpaceGrotesk family', () {
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        contains('SpaceGrotesk'),
      );
    });
  });

  group('Theme widget integration', () {
    testWidgets('MaterialApp renders with theme without errors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: Center(child: Text('uncertain-envelopes-2')),
          ),
        ),
      );

      expect(find.text('uncertain-envelopes-2'), findsOneWidget);
    });

    testWidgets('ElevatedButton renders with correct theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('TEST'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('TEST'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Card renders with ghost border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(
            body: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('Card'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('TextFormField renders with themed input decoration',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });
  });
}
