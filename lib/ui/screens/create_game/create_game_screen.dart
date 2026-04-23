import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Stream C — Create Game flow (plan C4). Form fields arrive in C4b–C4f.
class CreateGameScreen extends StatelessWidget {
  const CreateGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('create-game-screen'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.xxxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CREATE GAME',
                key: const ValueKey('create-game-heading'),
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
