import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/account/profile_username_rules.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/neon_button.dart';
import 'profile_view_data.dart';

/// Keeps keystrokes lowercase without fighting IME composes too aggressively.
class _LowercaseFilteringFormatter extends TextInputFormatter {
  const _LowercaseFilteringFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    if (lower == newValue.text) return newValue;
    return TextEditingValue(
      text: lower,
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}

/// User profile (**C8**), ref `design-uncertain-envelopes-2/admin_game_trading_dashboard_1/code.html`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.data,
    this.onUsernameCommit,
    this.onSignOut,
    this.onGameHistoryTap,
    this.onDeleteAccount,
  });

  final ProfileViewData data;

  /// Returns [ProfileUsernameSubmitResult.taken] when rename is unavailable.
  /// When `null`/omitted, defaults to **instant success**.
  final Future<ProfileUsernameSubmitResult> Function(String lowercaseUsername)?
  onUsernameCommit;

  /// Stream C hooks (no backend).
  final VoidCallback? onSignOut;
  final VoidCallback? onGameHistoryTap;
  final VoidCallback? onDeleteAccount;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _committedUsernameNormalized;
  late final TextEditingController _controller;
  late final FocusNode _focusUsername;

  /// User tapped edit — field is editable and focused until cancel or submit.
  var _usernameEditing = false;

  var _submittingUsername = false;

  /// Shown inline after **[ProfileUsernameSubmitResult.taken]**.
  var _usernameTakenBanner = false;
  String? _usernameRejectedNormalized;

  @override
  void initState() {
    super.initState();
    _committedUsernameNormalized = _normalize(widget.data.username);
    _controller = TextEditingController(text: _committedUsernameNormalized);
    _controller.addListener(_onUsernameFieldChanged);
    _focusUsername = FocusNode(debugLabel: 'profile-username');
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalize(widget.data.username);
    if (!_usernameEditing &&
        oldWidget.data.username != widget.data.username &&
        next != _committedUsernameNormalized) {
      _committedUsernameNormalized = next;
      _controller
        ..removeListener(_onUsernameFieldChanged)
        ..text = _committedUsernameNormalized
        ..addListener(_onUsernameFieldChanged);
      setState(() {});
    }
  }

  static String _normalize(String s) => s.trim().toLowerCase();

  void _onUsernameFieldChanged() {
    final raw = _controller.text;
    final lower = raw.toLowerCase();
    if (lower != raw) {
      final sel = _controller.selection;
      final off = sel.isValid
          ? sel.extentOffset.clamp(0, lower.length)
          : lower.length;
      _controller
        ..removeListener(_onUsernameFieldChanged)
        ..text = lower
        ..selection = TextSelection.collapsed(offset: off)
        ..addListener(_onUsernameFieldChanged);
    }

    final n = _normalize(_controller.text);
    final clearTaken =
        _usernameTakenBanner &&
        _usernameRejectedNormalized != null &&
        n != _usernameRejectedNormalized;
    setState(() {
      if (clearTaken) {
        _usernameTakenBanner = false;
        _usernameRejectedNormalized = null;
      }
    });
  }

  bool get _dirtyForSubmit =>
      _normalize(_controller.text) != _committedUsernameNormalized;

  bool get _greyTakenTick =>
      _usernameTakenBanner &&
      _usernameRejectedNormalized != null &&
      _normalize(_controller.text) == _usernameRejectedNormalized;

  void _cancelUsernameEditPreserveCommitted() {
    setState(() {
      _usernameEditing = false;
      _usernameTakenBanner = false;
      _usernameRejectedNormalized = null;
      _controller
        ..removeListener(_onUsernameFieldChanged)
        ..text = _committedUsernameNormalized
        ..addListener(_onUsernameFieldChanged);
    });
  }

  void _startUsernameEdit() {
    setState(() => _usernameEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusUsername.requestFocus();
      final len = _controller.text.length;
      _controller.selection = TextSelection.collapsed(offset: len);
    });
  }

  Future<void> _submitUsernameRename() async {
    if (_greyTakenTick ||
        !_dirtyForSubmit ||
        _submittingUsername ||
        !_usernameEditing) {
      return;
    }

    final next = _normalize(_controller.text);
    final validation = validateUsernameForProfile(next);
    if (validation != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validation)));
      return;
    }

    if (next == _committedUsernameNormalized) {
      setState(() => _usernameEditing = false);
      FocusScope.of(context).unfocus();
      return;
    }

    final cb =
        widget.onUsernameCommit ??
        (_) async => ProfileUsernameSubmitResult.success;

    setState(() => _submittingUsername = true);

    ProfileUsernameSubmitResult result;
    try {
      result = await cb(next);
    } finally {
      if (mounted) setState(() => _submittingUsername = false);
    }

    if (!mounted) return;

    switch (result) {
      case ProfileUsernameSubmitResult.success:
        setState(() {
          _committedUsernameNormalized = next;
          _usernameEditing = false;
          _usernameTakenBanner = false;
          _usernameRejectedNormalized = null;
          _controller
            ..removeListener(_onUsernameFieldChanged)
            ..text = _committedUsernameNormalized
            ..addListener(_onUsernameFieldChanged);
        });
        FocusScope.of(context).unfocus();
      case ProfileUsernameSubmitResult.taken:
        setState(() {
          _usernameTakenBanner = true;
          _usernameRejectedNormalized = next;
        });
    }
  }

  void _branchNav(int ix, BuildContext ctx) {
    switch (ix) {
      case 0:
        ctx.go(AppRoutes.home);
      case 1:
        ctx.go(AppRoutes.create);
      default:
        ctx.go(AppRoutes.orders);
    }
  }

  Widget _usernameTrailingIcon() {
    if (!_usernameEditing) {
      return IconButton(
        key: const ValueKey('profile-username-edit-btn'),
        icon: Icon(Icons.edit_outlined, color: AppColors.primary),
        tooltip: 'Edit username',
        onPressed: _startUsernameEdit,
      );
    }

    final submitDisabled =
        !_dirtyForSubmit || _greyTakenTick || _submittingUsername;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const ValueKey('profile-username-cancel-edit-btn'),
          icon: Icon(Icons.close, color: AppColors.textSecondary),
          tooltip: 'Cancel editing',
          onPressed: () {
            _cancelUsernameEditPreserveCommitted();
            FocusScope.of(context).unfocus();
          },
        ),
        IconButton(
          key: const ValueKey('profile-username-submit-btn'),
          icon: _submittingUsername
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: submitDisabled
                        ? AppColors.textDisabled
                        : AppColors.primary,
                  ),
                )
              : Icon(
                  Icons.check,
                  color: submitDisabled
                      ? AppColors.textDisabled
                      : AppColors.primary,
                ),
          tooltip: switch ((_greyTakenTick, _dirtyForSubmit)) {
            (true, _) => 'Username taken — change text to retry',
            (_, false) => 'Change username before saving',
            _ => 'Confirm username',
          },
          onPressed: submitDisabled ? null : _submitUsernameRename,
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Delete account',
      message:
          'This cannot be undone. All your progress and pending orders tied to '
          'this account will be lost.',
      confirmLabel: 'Delete account',
      cancelLabel: 'Back',
      destructive: true,
      uppercaseActionLabels: false,
    );
    if (ok == true) widget.onDeleteAccount?.call();
  }

  @override
  void dispose() {
    _controller.removeListener(_onUsernameFieldChanged);
    _focusUsername.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('profile-scaffold'),
      backgroundColor: AppColors.background,
      bottomNavigationBar: Material(
        color: AppColors.background,
        child: AppBottomNavigationBar(
          visualSelectionEnabled: false,
          currentIndex: 0,
          onTap: (ix) => _branchNav(ix, context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ProfileStickyHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.sectionGap + 96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionLabel('Username'),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.outline),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Profile username field',
                              child: TextField(
                                key: const ValueKey('profile-username-field'),
                                controller: _controller,
                                focusNode: _focusUsername,
                                readOnly: !_usernameEditing,
                                showCursor: _usernameEditing,
                                enableInteractiveSelection: _usernameEditing,
                                autocorrect: false,
                                keyboardType: TextInputType.visiblePassword,
                                textCapitalization: TextCapitalization.none,
                                style: AppTypography.monoSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  letterSpacing: 0.35,
                                  color: AppColors.textPrimary,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9_-]'),
                                  ),
                                  const _LowercaseFilteringFormatter(),
                                  LengthLimitingTextInputFormatter(
                                    AppConstants.maxUsernameLength,
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _usernameTrailingIcon(),
                        ],
                      ),
                    ),
                    if (_usernameTakenBanner) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Username taken',
                        key: const ValueKey('profile-username-taken-msg'),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    _sectionLabel('Email Address'),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.outline),
                      ),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              widget.data.email,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0,
                                height: 1.35,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _sectionLabel('Performance Stats'),
                    Row(
                      children: [
                        Expanded(
                          child: _stattile(
                            'Win Rate',
                            '${widget.data.winRatePct}%',
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _stattile(
                            'Games Played',
                            '${widget.data.gamesPlayed}',
                            AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sectionGap.toDouble()),
                    NeonButton(
                      key: const ValueKey('profile-game-history-row'),
                      label: 'Game History',
                      variant: NeonButtonVariant.outline,
                      expand: true,
                      leadingIcon: Icons.history,
                      trailingIcon: Icons.chevron_right,
                      dense: false,
                      onPressed: widget.onGameHistoryTap,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    NeonButton(
                      key: const ValueKey('profile-sign-out-btn'),
                      label: 'Sign Out',
                      variant: NeonButtonVariant.outline,
                      expand: true,
                      leadingIcon: Icons.logout,
                      dense: false,
                      onPressed: widget.onSignOut,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    NeonButton(
                      key: const ValueKey('profile-delete-account-btn'),
                      label: 'Delete Account',
                      variant: NeonButtonVariant.outlineDanger,
                      expand: true,
                      leadingIcon: Icons.delete_forever,
                      dense: false,
                      onPressed: _confirmDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stattile(String label, String value, Color valueColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.statValue.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      t.toUpperCase(),
      style: AppTypography.bodySmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textTertiary,
        letterSpacing: 0.85,
        height: 1.4,
      ),
    ),
  );
}

class _ProfileStickyHeader extends StatelessWidget {
  const _ProfileStickyHeader();

  static const double _edgeSlot = 48;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.96),
            border: const Border(
              bottom: BorderSide(color: AppColors.outlineSubtle),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: 12,
          ),
          child: SizedBox(
            height: _edgeSlot,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _edgeSlot),
                  child: Text(
                    'UNCERTAIN ENVELOPES',
                    textAlign: TextAlign.center,
                    style: AppTypography.brandHeader,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _edgeSlot,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Back',
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(width: _edgeSlot, height: _edgeSlot),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
