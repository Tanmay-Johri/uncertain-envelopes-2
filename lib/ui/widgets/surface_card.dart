import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The universal container used for every bounded panel in the app.
///
/// A [SurfaceCard] is a dark `surface-container` surface with an optional
/// ghost border (white @ 10%) and rounded corners. It replaces [Card] in
/// app code because the Material [CardTheme] does not expose a
/// `surfaceTintColor` hook that survives rebuilds on Web, and because we
/// want press feedback and a variant without padding.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.backgroundColor,
    this.border = true,
    this.radius = AppRadius.md,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// If null, defaults to [AppColors.surfaceContainer].
  final Color? backgroundColor;

  /// When true, a 1px ghost border is drawn.
  final bool border;

  /// Corner radius. Defaults to [AppRadius.md] (8).
  final double radius;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor ?? AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(radius),
      border: border ? Border.all(color: AppColors.outline) : null,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );
  }
}
