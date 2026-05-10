import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'neon_button.dart';

/// Message + **Retry** for failed async fetches (Phase 3 POL3 / offline recovery).
class FetchedErrorPanel extends StatelessWidget {
  const FetchedErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  static const retryButtonKey = ValueKey<String>('fetched-error-retry');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              NeonButton(
                key: retryButtonKey,
                label: 'Retry',
                variant: NeonButtonVariant.outline,
                expand: false,
                trailingIcon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
