import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Visual variant for [NeonButton].
///
/// - [primary]: solid green with black text and a soft green glow. Reserved
///   for the single most important action on a screen (e.g. Start Game).
/// - [destructive]: solid red with white text and a red glow. Used for
///   actions that remove, end, kick, or cancel.
/// - [outline]: transparent background with a ghost border. Used for
///   secondary actions and navigation.
enum NeonButtonVariant { primary, destructive, outline }

/// The single shared button used across the app.
///
/// It is deliberately not a thin wrapper over [ElevatedButton] because the
/// design system has variant-specific glows, letter spacing, and uppercase
/// rules that would be fragile to re-apply at every call site.
class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NeonButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.expand = true,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NeonButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  /// When true the button fills its parent horizontally. When false it
  /// sizes to its content (useful for inline actions inside rows).
  final bool expand;

  /// When true the button uses a compact 36px height instead of 48px.
  final bool dense;

  bool get _enabled => onPressed != null;

  Color _background() {
    if (!_enabled) return AppColors.surfaceContainer;
    switch (variant) {
      case NeonButtonVariant.primary:
        return AppColors.primary;
      case NeonButtonVariant.destructive:
        return AppColors.secondary;
      case NeonButtonVariant.outline:
        return Colors.transparent;
    }
  }

  Color _foreground() {
    if (!_enabled) return AppColors.textDisabled;
    switch (variant) {
      case NeonButtonVariant.primary:
        return AppColors.background;
      case NeonButtonVariant.destructive:
      case NeonButtonVariant.outline:
        return AppColors.textPrimary;
    }
  }

  BorderSide? _border() {
    if (variant == NeonButtonVariant.outline) {
      return const BorderSide(color: AppColors.outline, width: 1);
    }
    return null;
  }

  List<BoxShadow> _shadows() {
    if (!_enabled) return const [];
    switch (variant) {
      case NeonButtonVariant.primary:
        return const [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ];
      case NeonButtonVariant.destructive:
        return [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ];
      case NeonButtonVariant.outline:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = dense ? 36.0 : 48.0;
    final fg = _foreground();

    final textStyle = (variant == NeonButtonVariant.primary
            ? AppTypography.buttonPrimary
            : AppTypography.buttonSecondary)
        .copyWith(color: fg);

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: fg),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: textStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: 18, color: fg),
        ],
      ],
    );

    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: _background(),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: _border() != null ? Border.fromBorderSide(_border()!) : null,
        boxShadow: _shadows(),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
            ),
            child: SizedBox(
              height: height,
              child: Align(
                alignment: Alignment.center,
                widthFactor: expand ? null : 1.0,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
