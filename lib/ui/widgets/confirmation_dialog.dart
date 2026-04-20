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
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  /// Show the dialog and resolve to the user's decision.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
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
            Text(title, style: AppTypography.screenTitle),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: AppTypography.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xxl),
            Row(
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
            ),
          ],
        ),
      ),
    );
  }
}
