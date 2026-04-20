import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Temporary placeholder screen used while individual screens are built
/// later in Stream C (C2-C10). Each placeholder displays a stable label
/// (`routeName`) in a single `Text` so router tests can assert the
/// correct route landed without ambiguity.
///
/// This file is prefixed with `_` as a convention reminder that it will
/// be removed once the real screens land.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.routeName, this.subtitle});

  final String routeName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(routeName, style: AppTypography.heroHeadline),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(subtitle!, style: AppTypography.bodyMedium),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Placeholder — real screen in a later Stream C unit.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
