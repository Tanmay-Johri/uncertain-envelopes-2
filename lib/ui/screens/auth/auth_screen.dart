import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../widgets/auth_tab_switcher.dart';
import '../../widgets/uncertain_envelopes_logo_mark.dart';
import 'login_form.dart';
import 'sign_up_form.dart';

/// Combined login + sign-up screen.
///
/// Owns only the current tab. The two underlying forms own their own
/// field state, so switching tabs does not wipe in-progress input —
/// the hidden form simply stays in memory. Validation/submission is
/// delegated to the forms; the screen forwards submissions to its own
/// [onLogIn] / [onSignUp] callbacks.
///
/// When no callbacks are provided, submissions are silently swallowed.
/// This is how we mock "no backend" during Stream C.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialTab = AuthTab.logIn,
    this.onLogIn,
    this.onSignUp,
    this.onForgotPassword,
  });

  final AuthTab initialTab;
  final ValueChanged<LoginSubmission>? onLogIn;
  final ValueChanged<SignUpSubmission>? onSignUp;
  final VoidCallback? onForgotPassword;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthTab _tab = widget.initialTab;

  static const double _scrollVerticalPadding = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        // Title is a fixed header; only the card scrolls / centres in the
        // space below so the brand never reads as part of the auth card.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                0,
              ),
              child: const _BrandTitle(),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minScrollChildHeight = (constraints.maxHeight -
                          _scrollVerticalPadding * 2)
                      .clamp(0.0, double.infinity);
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      _scrollVerticalPadding,
                      AppSpacing.xxl,
                      _scrollVerticalPadding + bottomInset,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: minScrollChildHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _AuthCard(
                            tab: _tab,
                            onTabChanged: (t) => setState(() => _tab = t),
                            onLogIn: widget.onLogIn,
                            onSignUp: widget.onSignUp,
                            onForgotPassword: widget.onForgotPassword,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: UncertainEnvelopesLogoMark(
        height: 28,
        alignment: Alignment.center,
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.tab,
    required this.onTabChanged,
    required this.onLogIn,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  final AuthTab tab;
  final ValueChanged<AuthTab> onTabChanged;
  final ValueChanged<LoginSubmission>? onLogIn;
  final ValueChanged<SignUpSubmission>? onSignUp;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTabSwitcher(
              selected: tab,
              onChanged: onTabChanged,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              // Both forms stay in the tree (so field state survives
              // tab switches) but only the active one takes layout
              // space, so the card shrinks/grows to fit it.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Visibility(
                    visible: tab == AuthTab.logIn,
                    maintainState: true,
                    maintainAnimation: true,
                    child: LoginForm(
                      onSubmit: (s) => onLogIn?.call(s),
                      onForgotTap: onForgotPassword,
                    ),
                  ),
                  Visibility(
                    visible: tab == AuthTab.signUp,
                    maintainState: true,
                    maintainAnimation: true,
                    child: SignUpForm(
                      onSubmit: (s) => onSignUp?.call(s),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
