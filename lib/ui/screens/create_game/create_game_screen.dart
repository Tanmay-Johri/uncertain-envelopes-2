import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Stream C — Create Game flow (plan C4). C4b: name + description validation.
class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final t = (value ?? '').trim();
    if (t.isEmpty) return 'Required';
    if (t.length > 32) return 'Max 32 characters';
    return null;
  }

  String? _validateDescription(String? value) {
    final t = (value ?? '').trim();
    if (t.length > 256) return 'Max 256 characters';
    return null;
  }

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
          child: Form(
            key: _formKey,
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
                Text('GAME NAME', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const ValueKey('create-game-name-field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Required, max 32 characters',
                  ),
                  validator: _validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('DESCRIPTION', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'OPTIONAL — MAX 256 CHARACTERS',
                  style: AppTypography.microLabel.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const ValueKey('create-game-description-field'),
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    hintText: 'Optional, max 256 characters',
                  ),
                  validator: _validateDescription,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
