import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/enums/end_condition.dart';
import '../../../data/enums/game_security.dart';
import '../../../data/enums/is_ranked.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/game_repository_provider.dart';
import '../../widgets/neon_button.dart';

/// Who can discover / join the game (plan C4).
enum CreateGameSecurity {
  public,
  private,
}

/// Bounds for the max-players stepper (plan C4 / PRD).
abstract final class CreateGamePlayerLimits {
  CreateGamePlayerLimits._();

  static const int min = 1;
  static const int max = 128;
  static const int defaultMaxPlayers = 16;
}

/// End condition for the session (PRD: timed vs endless).
///
/// Only [timed] shows the duration stepper; [endless] ends when an admin stops it.
enum CreateGameEndCondition {
  timed,
  endless,
}

/// Bounds for timed-game duration (minutes).
abstract final class CreateGameDurationLimits {
  CreateGameDurationLimits._();

  static const int minMinutes = 1;
  static const int maxMinutes = 600;
  static const int defaultMinutes = 30;
}

int _normalizeDurationMinutesInput(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return CreateGameDurationLimits.minMinutes;
  final v = double.tryParse(t);
  if (v == null) return CreateGameDurationLimits.minMinutes;
  final floored = v.floor();
  return floored.clamp(
    CreateGameDurationLimits.minMinutes,
    CreateGameDurationLimits.maxMinutes,
  );
}

int _normalizeMaxPlayersInput(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return CreateGamePlayerLimits.min;
  final v = double.tryParse(t);
  if (v == null) return CreateGamePlayerLimits.min;
  final floored = v.floor();
  return floored.clamp(
    CreateGamePlayerLimits.min,
    CreateGamePlayerLimits.max,
  );
}

/// Local payload for create-game submit (plan **C4f**); no backend call here.
@immutable
class CreateGameDraft {
  const CreateGameDraft({
    required this.name,
    required this.description,
    required this.security,
    required this.ranked,
    required this.maxPlayers,
    required this.endCondition,
    required this.durationMinutes,
  });

  final String name;
  final String description;
  final CreateGameSecurity security;
  final bool ranked;
  final int maxPlayers;
  final CreateGameEndCondition endCondition;

  /// Minutes when [endCondition] is [CreateGameEndCondition.timed]; otherwise
  /// `null` (endless).
  final int? durationMinutes;

  /// Stable JSON-style map for future API wiring.
  Map<String, Object?> toJson() => {
        'name': name,
        'description': description,
        'security': security.name,
        'ranked': ranked,
        'maxPlayers': maxPlayers,
        'endCondition': endCondition.name,
        'durationMinutes': durationMinutes,
      };

  @override
  bool operator ==(Object other) =>
      other is CreateGameDraft &&
      other.name == name &&
      other.description == description &&
      other.security == security &&
      other.ranked == ranked &&
      other.maxPlayers == maxPlayers &&
      other.endCondition == endCondition &&
      other.durationMinutes == durationMinutes;

  @override
  int get hashCode => Object.hash(
        name,
        description,
        security,
        ranked,
        maxPlayers,
        endCondition,
        durationMinutes,
      );
}

/// Stream C — Create Game flow (plan C4). Visual layout follows
/// `design-uncertain-envelopes-2/.../admin_game_trading_dashboard_5/code.html`.
class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key, this.onSubmit});

  /// When non-null and the form validates, called with a single draft (C4f).
  ///
  /// When null, the screen submits via [gameRepositoryProvider] and
  /// navigates to the new game's lobby (requires a signed-in player).
  final Future<void> Function(CreateGameDraft)? onSubmit;

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _maxPlayersController;
  late final FocusNode _maxPlayersFocusNode;
  late final TextEditingController _durationMinutesController;
  late final FocusNode _durationFocusNode;

  CreateGameSecurity _security = CreateGameSecurity.private;
  bool _ranked = false;
  int _maxPlayers = CreateGamePlayerLimits.defaultMaxPlayers;
  CreateGameEndCondition _endCondition = CreateGameEndCondition.timed;
  int _durationMinutes = CreateGameDurationLimits.defaultMinutes;
  String? _submitRepositoryError;

  static const _inputFill = AppColors.surfaceContainer;

  @override
  void initState() {
    super.initState();
    _maxPlayersController = TextEditingController(text: '$_maxPlayers');
    _maxPlayersFocusNode = FocusNode();
    _maxPlayersFocusNode.addListener(_onMaxPlayersFocusChange);
    _durationMinutesController = TextEditingController(
      text: '$_durationMinutes',
    );
    _durationFocusNode = FocusNode();
    _durationFocusNode.addListener(_onDurationFocusChange);
  }

  void _onMaxPlayersFocusChange() {
    if (!_maxPlayersFocusNode.hasFocus) {
      _commitMaxPlayersFromField();
    }
  }

  void _commitMaxPlayersFromField() {
    final next = _normalizeMaxPlayersInput(_maxPlayersController.text);
    setState(() {
      _maxPlayers = next;
      _maxPlayersController.text = '$next';
    });
  }

  void _adjustMaxPlayersBy(int delta) {
    final current = _normalizeMaxPlayersInput(_maxPlayersController.text);
    final next = (current + delta).clamp(
      CreateGamePlayerLimits.min,
      CreateGamePlayerLimits.max,
    );
    setState(() {
      _maxPlayers = next;
      _maxPlayersController.text = '$next';
    });
  }

  void _onDurationFocusChange() {
    if (!_durationFocusNode.hasFocus) {
      _commitDurationFromField();
    }
  }

  void _commitDurationFromField() {
    final next = _normalizeDurationMinutesInput(_durationMinutesController.text);
    setState(() {
      _durationMinutes = next;
      _durationMinutesController.text = '$next';
    });
  }

  void _adjustDurationBy(int delta) {
    final current = _normalizeDurationMinutesInput(
      _durationMinutesController.text,
    );
    final next = (current + delta).clamp(
      CreateGameDurationLimits.minMinutes,
      CreateGameDurationLimits.maxMinutes,
    );
    setState(() {
      _durationMinutes = next;
      _durationMinutesController.text = '$next';
    });
  }

  @override
  void dispose() {
    _maxPlayersFocusNode.removeListener(_onMaxPlayersFocusChange);
    _maxPlayersFocusNode.dispose();
    _maxPlayersController.dispose();
    _durationFocusNode.removeListener(_onDurationFocusChange);
    _durationFocusNode.dispose();
    _durationMinutesController.dispose();
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

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _inputFill,
    );
  }

  Future<void> _handleSubmit() async {
    _commitMaxPlayersFromField();
    _commitDurationFromField();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final draft = CreateGameDraft(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      security: _security,
      ranked: _ranked,
      maxPlayers: _maxPlayers,
      endCondition: _endCondition,
      durationMinutes: _endCondition == CreateGameEndCondition.timed
          ? _durationMinutes
          : null,
    );
    final callback = widget.onSubmit;
    if (callback != null) {
      await callback(draft);
      return;
    }
    final player = ref.read(authControllerProvider).valueOrNull;
    if (!mounted) return;
    if (player == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a game.')),
      );
      return;
    }
    final desc = draft.description.trim();
    final gameSecurity = switch (draft.security) {
      CreateGameSecurity.public => GameSecurity.public,
      CreateGameSecurity.private => GameSecurity.private,
    };
    final isRanked =
        draft.ranked ? IsRanked.ranked : IsRanked.casual;
    final endCondition = switch (draft.endCondition) {
      CreateGameEndCondition.timed => EndCondition.timed,
      CreateGameEndCondition.endless => EndCondition.endless,
    };
    final durationSeconds =
        draft.endCondition == CreateGameEndCondition.timed &&
                draft.durationMinutes != null
            ? draft.durationMinutes! * 60
            : null;
    setState(() => _submitRepositoryError = null);
    try {
      final gameId = await ref.read(gameRepositoryProvider).createGameAndReturnGameId(
            adminPlayerId: player.playerId,
            gameName: draft.name,
            gameDescription: desc.isEmpty ? null : desc,
            gameSecurity: gameSecurity,
            isRanked: isRanked,
            gameMaxPlayers: draft.maxPlayers,
            endCondition: endCondition,
            totalDecidedDurationSeconds: durationSeconds,
          );
      if (!mounted) return;
      context.go(AppRoutes.gameLobby(gameId));
    } on GameRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _submitRepositoryError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitRepositoryError = '$e');
    }
  }

  bool get _showDuration => _endCondition == CreateGameEndCondition.timed;

  String _endConditionLabel(CreateGameEndCondition v) {
    switch (v) {
      case CreateGameEndCondition.timed:
        return 'Timed';
      case CreateGameEndCondition.endless:
        return 'Endless';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      key: const ValueKey('create-game-screen'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxxl + bottomInset,
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
                style: AppTypography.screenTitle,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'GAME NAME ',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TextSpan(
                      text: '*',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.secondary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.labelGap),
              TextFormField(
                key: const ValueKey('create-game-name-field'),
                controller: _nameController,
                style: AppTypography.monoMedium,
                decoration: _fieldDecoration(
                  hint: 'e.g. Alpha Flight 01',
                ),
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'DESCRIPTION',
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.labelGap),
              TextFormField(
                key: const ValueKey('create-game-description-field'),
                controller: _descriptionController,
                maxLines: 3,
                style: AppTypography.monoMedium,
                decoration: _fieldDecoration(
                  hint:
                      'OPTIONAL - MAX 256 CHARACTERS\n(Brief mission statement for traders)',
                ),
                validator: _validateDescription,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'SECURITY ACCESS',
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.labelGap),
              Row(
                children: [
                  Expanded(
                    child: _SecurityAccessTile(
                      key: const ValueKey('create-game-security-public'),
                      icon: Icons.public_outlined,
                      label: 'Public',
                      selected: _security == CreateGameSecurity.public,
                      onTap: () =>
                          setState(() => _security = CreateGameSecurity.public),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SecurityAccessTile(
                      key: const ValueKey('create-game-security-private'),
                      icon: Icons.lock_outline,
                      label: 'Private',
                      selected: _security == CreateGameSecurity.private,
                      onTap: () => setState(
                        () => _security = CreateGameSecurity.private,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _security == CreateGameSecurity.public
                    ? 'Anyone can see this game under Public games.'
                    : 'Only people with the joining code can join.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outline),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ranked Mode',
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Affects stats',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const ValueKey('create-game-ranked-switch'),
                      value: _ranked,
                      onChanged: (v) => setState(() => _ranked = v),
                      activeThumbColor: AppColors.textPrimary,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: AppColors.textPrimary,
                      inactiveTrackColor: AppColors.background,
                      trackOutlineColor:
                          WidgetStateProperty.all(AppColors.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'MAXIMUM PLAYERS',
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.labelGap),
              Row(
                children: [
                  _StepperSideButton(
                    key: const ValueKey('create-game-max-players-minus'),
                    icon: Icons.remove,
                    onPressed: _maxPlayers > CreateGamePlayerLimits.min
                        ? () => _adjustMaxPlayersBy(-1)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('create-game-max-players-value'),
                      controller: _maxPlayersController,
                      focusNode: _maxPlayersFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: AppTypography.statValue,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainer,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.md,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      onEditingComplete: _commitMaxPlayersFromField,
                      onSubmitted: (_) => _commitMaxPlayersFromField(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StepperSideButton(
                    key: const ValueKey('create-game-max-players-plus'),
                    icon: Icons.add,
                    onPressed: _maxPlayers < CreateGamePlayerLimits.max
                        ? () => _adjustMaxPlayersBy(1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                'END CONDITION',
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.labelGap),
              InputDecorator(
                key: const ValueKey('create-game-end-dropdown'),
                decoration: _fieldDecoration(hint: '').copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CreateGameEndCondition>(
                    value: _endCondition,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceContainer,
                    style: AppTypography.monoMedium,
                    icon: const Icon(
                      Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                    items: CreateGameEndCondition.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(_endConditionLabel(e)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _endCondition = v);
                      if (v == CreateGameEndCondition.timed) {
                        _durationMinutesController.text = '$_durationMinutes';
                      }
                    },
                  ),
                ),
              ),
              if (_showDuration) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Trading ends automatically after the duration below.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.outlineSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'DURATION (MINUTES)',
                        style: AppTypography.microLabel.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _StepperSideButton(
                            key: const ValueKey(
                              'create-game-duration-minus',
                            ),
                            icon: Icons.remove,
                            onPressed: _durationMinutes >
                                    CreateGameDurationLimits.minMinutes
                                ? () => _adjustDurationBy(-1)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextField(
                              key: const ValueKey(
                                'create-game-duration-value',
                              ),
                              controller: _durationMinutesController,
                              focusNode: _durationFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textAlign: TextAlign.center,
                              style: AppTypography.statValue.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.background,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.md,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: const BorderSide(
                                    color: AppColors.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: const BorderSide(
                                    color: AppColors.outline,
                                  ),
                                ),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              onEditingComplete: _commitDurationFromField,
                              onSubmitted: (_) => _commitDurationFromField(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _StepperSideButton(
                            key: const ValueKey(
                              'create-game-duration-plus',
                            ),
                            icon: Icons.add,
                            onPressed: _durationMinutes <
                                    CreateGameDurationLimits.maxMinutes
                                ? () => _adjustDurationBy(1)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Session will auto-close after timer expires',
                        textAlign: TextAlign.center,
                        style: AppTypography.microLabel.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Trading runs until an admin ends it.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              if (_submitRepositoryError != null) ...[
                Text(
                  _submitRepositoryError!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                NeonButton(
                  key: const ValueKey('create-game-submit-retry'),
                  label: 'Retry',
                  variant: NeonButtonVariant.outline,
                  expand: false,
                  trailingIcon: Icons.refresh,
                  onPressed: () {
                    unawaited(_handleSubmit());
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              NeonButton(
                key: const ValueKey('create-game-submit'),
                label: 'Create Game',
                onPressed: () {
                  unawaited(_handleSubmit());
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _SecurityAccessTile extends StatelessWidget {
  const _SecurityAccessTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperSideButton extends StatelessWidget {
  const _StepperSideButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
