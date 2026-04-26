import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'neon_button.dart';

/// A compact, destructive-aware confirmation dialog.
///
/// Use this for any irreversible user action: kicking a player, deleting
/// an account, cancelling an order, discarding a game. The confirm button
/// colour is driven by [destructive]. Returns `true` on confirm, `false`
/// or `null` on dismiss/cancel.
///
/// Example:
/// ```dart
/// final ok = await ConfirmationDialog.show(
///   context,
///   title: 'Kick player?',
///   message: 'Jane will lose her spot.',
///   confirmLabel: 'Kick',
///   destructive: true,
/// );
/// if (ok == true) { ... }
/// ```
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.uppercaseActionLabels = true,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  /// When false, action labels are shown as given (e.g. "Back" / "Cancel").
  /// [NeonButton] always uppercases; use false for product copy that must
  /// match a spec exactly.
  final bool uppercaseActionLabels;

  /// Show the dialog and resolve to the user's decision.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    bool uppercaseActionLabels = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        uppercaseActionLabels: uppercaseActionLabels,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.trim().isNotEmpty) ...[
              Text(title, style: AppTypography.screenTitle),
            ],
            if (message != null) ...[
              if (title.trim().isNotEmpty) const SizedBox(height: AppSpacing.md),
              Text(message!, style: AppTypography.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xxl),
            _actionRow(context),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(BuildContext context) {
    if (uppercaseActionLabels) {
      return Row(
        children: [
          Expanded(
            child: NeonButton(
              label: cancelLabel,
              variant: NeonButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: NeonButton(
              label: confirmLabel,
              variant: destructive
                  ? NeonButtonVariant.destructive
                  : NeonButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      );
    }

    final confirmBg =
        destructive ? AppColors.secondary : AppColors.primary;
    final confirmFg =
        destructive ? AppColors.textPrimary : AppColors.background;
    final confirmStyle = destructive
        ? AppTypography.buttonSecondary.copyWith(color: confirmFg)
        : AppTypography.buttonPrimary.copyWith(color: confirmFg);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              side: const BorderSide(color: AppColors.outline, width: 1),
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(
              cancelLabel,
              style: AppTypography.buttonSecondary.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              backgroundColor: confirmBg,
              foregroundColor: confirmFg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              elevation: 0,
            ),
            child: Text(confirmLabel, style: confirmStyle),
          ),
        ),
      ],
    );
  }
}
