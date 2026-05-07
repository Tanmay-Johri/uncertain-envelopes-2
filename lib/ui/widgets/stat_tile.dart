import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Stat card: label + large mono value; border / label / value tint from [signedValue].
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.signedValue,
  });

  final String label;
  final String value;

  /// Used only for green / red / neutral styling (not shown as text).
  final double signedValue;

  Color get _accent {
    if (signedValue > 0) return AppColors.primary;
    if (signedValue < 0) return AppColors.secondary;
    return AppColors.textTertiary;
  }

  Color get _borderColor => signedValue == 0
      ? AppColors.outline
      : _accent.withValues(alpha: 0.2);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
              letterSpacing: 0.15,
              color: signedValue == 0
                  ? AppColors.textTertiary
                  : _accent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.monoLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: signedValue == 0 ? AppColors.textPrimary : _accent,
              height: 1.1,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
