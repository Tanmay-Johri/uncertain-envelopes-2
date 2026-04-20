import 'dart:ui';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF40F320);
  static const secondary = Color(0xFFFF3B30);
  static const tertiary = Color(0xFF8D363C);

  // Surfaces — ordered by luminosity (darkest → lightest)
  static const background = Color(0xFF1F1F1F);
  static const surfaceContainerLow = Color(0xFF1E1E1E);
  static const surfaceContainer = Color(0xFF2A2A2A);
  static const surfaceContainerHigh = Color(0xFF333333);

  // Themed surfaces (green-tinted)
  static const surfaceDark = Color(0xFF162314);
  static const surfaceHighlight = Color(0xFF20301D);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF94A3B8); // slate-400
  static const textTertiary = Color(0xFF64748B); // slate-500
  static const textDisabled = Color(0xFF475569); // slate-600

  // Outline / borders
  static const outline = Color(0x1AFFFFFF); // white/10
  static const outlineSubtle = Color(0x0DFFFFFF); // white/5

  // Functional
  static const success = primary;
  static const error = secondary;

  // Glow & shadow helpers (use with BoxShadow)
  static const primaryGlow = Color(0x4D40F320); // primary @ 30%
  static const primaryGlowSubtle = Color(0x3340F320); // primary @ 20%
}
