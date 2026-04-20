import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Logical font family names.
///
/// These are also the exact `family` values declared in pubspec.yaml,
/// so any `TextStyle(fontFamily: AppFontFamilies.display)` resolves to
/// the bundled TTFs without a network fetch.
abstract final class AppFontFamilies {
  static const display = 'Epilogue';
  static const body = 'SpaceGrotesk';
  static const mono = 'FiraCode';
}

/// Centralised semantic typography scale.
///
/// Fonts are bundled locally via pubspec.yaml, so every style is just a
/// plain `TextStyle` and can be `const`-constructed, giving better tree
/// shaking and zero runtime cost.
abstract final class AppTypography {
  // ── Display / Headlines (Epilogue) ─────────────────────────────

  static const heroHeadline = TextStyle(
    fontFamily: AppFontFamilies.display,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const sectionHeader = TextStyle(
    fontFamily: AppFontFamilies.display,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const screenTitle = TextStyle(
    fontFamily: AppFontFamilies.display,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ── Body / Interface (Space Grotesk) ───────────────────────────

  static const bodyLarge = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const label = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
    height: 1.4,
  );

  static const microLabel = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 1.5,
    height: 1.4,
  );

  // ── Monospace / Data (Fira Code) ───────────────────────────────

  static const monoLarge = TextStyle(
    fontFamily: AppFontFamilies.mono,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const monoMedium = TextStyle(
    fontFamily: AppFontFamilies.mono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const monoSmall = TextStyle(
    fontFamily: AppFontFamilies.mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const statValue = TextStyle(
    fontFamily: AppFontFamilies.mono,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const timerDisplay = TextStyle(
    fontFamily: AppFontFamilies.mono,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -2,
    height: 1.1,
  );

  // ── Brand header ───────────────────────────────────────────────

  static const brandHeader = TextStyle(
    fontFamily: AppFontFamilies.display,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 3.2,
    height: 1.4,
  );

  // ── Button text ────────────────────────────────────────────────

  static const buttonPrimary = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.background,
    letterSpacing: 1.2,
    height: 1.4,
  );

  static const buttonSecondary = TextStyle(
    fontFamily: AppFontFamilies.body,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
    height: 1.4,
  );
}
