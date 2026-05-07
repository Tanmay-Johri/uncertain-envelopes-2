import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      surface: AppColors.surfaceContainer,
      error: AppColors.error,
      onPrimary: AppColors.background,
      onSecondary: AppColors.textPrimary,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textPrimary,
      outline: AppColors.outline,
    ),
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,

    // Default font for anything that doesn't explicitly set one.
    fontFamily: AppFontFamilies.body,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.brandHeader.copyWith(
        color: AppColors.textSecondary,
      ),
    ),

    // Bottom nav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xF21F1F1F),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: AppFontFamilies.body,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AppFontFamilies.body,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.outline),
      ),
      margin: EdgeInsets.zero,
    ),

    // Inputs
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      hintStyle: const TextStyle(color: AppColors.textDisabled),
      labelStyle: AppTypography.label,
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTypography.buttonPrimary,
        elevation: 0,
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: const BorderSide(color: AppColors.outline),
        textStyle: AppTypography.buttonSecondary,
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.outlineSubtle,
      thickness: 1,
      space: 0,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainer,
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelStyle: AppTypography.microLabel,
    ),

    splashColor: AppColors.primary.withValues(alpha: 0.1),
    highlightColor: AppColors.primary.withValues(alpha: 0.05),
  );
}
