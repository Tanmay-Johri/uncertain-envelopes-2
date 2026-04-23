import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Who can discover / join the game (plan C4).
enum CreateGameSecurity {
  public,
  private,
}

/// Bounds for the max-players stepper (plan C4 / PRD).
abstract final class CreateGamePlayerLimits {
  CreateGamePlayerLimits._();

  static const int min = 1;
  static const int max = 100;
  static const int defaultMaxPlayers = 8;
}

/// Stream C — Create Game flow (plan C4). C4b–C4d: form through max players.
class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CreateGameSecurity _security = CreateGameSecurity.public;
  bool _ranked = false;
  int _maxPlayers = CreateGamePlayerLimits.defaultMaxPlayers;

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
                const SizedBox(height: AppSpacing.lg),
                Text('SECURITY', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<CreateGameSecurity>(
                  key: const ValueKey('create-game-security-segmented'),
                  segments: const [
                    ButtonSegment<CreateGameSecurity>(
                      value: CreateGameSecurity.public,
                      label: Text('Public'),
                      icon: Icon(Icons.public_outlined, size: 18),
                    ),
                    ButtonSegment<CreateGameSecurity>(
                      value: CreateGameSecurity.private,
                      label: Text('Private'),
                      icon: Icon(Icons.lock_outline, size: 18),
                    ),
                  ],
                  selected: {_security},
                  onSelectionChanged: (next) {
                    if (next.isEmpty) return;
                    setState(() => _security = next.first);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _security == CreateGameSecurity.public
                      ? 'Anyone can see this game under Public games.'
                      : 'Only people with the joining code can join.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  key: const ValueKey('create-game-ranked-tile'),
                  title: Text(
                    'RANKED',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Counts toward competitive stats when backend supports it.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  value: _ranked,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                  inactiveThumbColor: AppColors.textSecondary,
                  inactiveTrackColor: AppColors.surfaceContainerHigh,
                  onChanged: (v) => setState(() => _ranked = v),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('MAX PLAYERS', style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${CreateGamePlayerLimits.min}–${CreateGamePlayerLimits.max} '
                  '(including you as host)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const ValueKey('create-game-max-players-minus'),
                      onPressed: _maxPlayers > CreateGamePlayerLimits.min
                          ? () => setState(() => _maxPlayers--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.textPrimary,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Text(
                        '$_maxPlayers',
                        key: const ValueKey('create-game-max-players-value'),
                        style: AppTypography.statValue.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('create-game-max-players-plus'),
                      onPressed: _maxPlayers < CreateGamePlayerLimits.max
                          ? () => setState(() => _maxPlayers++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
