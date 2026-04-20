import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';

/// Size preset for a [MonoText] block.
enum MonoTextSize { small, medium, large, stat, timer }

/// A thin wrapper around [Text] that enforces the FiraCode monospace
/// family for every piece of numeric or tabular data (prices, deltas,
/// quantities, timers, codes).
///
/// Centralising this means every delta/PnL display automatically picks
/// up the same vertical rhythm, and a future font swap is a one-line
/// change in [AppTypography].
class MonoText extends StatelessWidget {
  const MonoText(
    this.text, {
    super.key,
    this.size = MonoTextSize.medium,
    this.color,
    this.textAlign,
    this.overflow,
    this.fontWeight,
    this.letterSpacing,
  });

  final String text;
  final MonoTextSize size;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;
  final double? letterSpacing;

  TextStyle _baseStyle() {
    switch (size) {
      case MonoTextSize.small:
        return AppTypography.monoSmall;
      case MonoTextSize.medium:
        return AppTypography.monoMedium;
      case MonoTextSize.large:
        return AppTypography.monoLarge;
      case MonoTextSize.stat:
        return AppTypography.statValue;
      case MonoTextSize.timer:
        return AppTypography.timerDisplay;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _baseStyle();
    final style = base.copyWith(
      color: color ?? base.color,
      fontWeight: fontWeight ?? base.fontWeight,
      letterSpacing: letterSpacing ?? base.letterSpacing,
    );
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}
