import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/neon_button.dart';
import 'auth_password_field_suffix.dart';

/// Credentials collected by the log-in form.
class LoginSubmission {
  const LoginSubmission({required this.identifier, required this.password});

  /// Either a username or an email — auth layer resolves later.
  final String identifier;
  final String password;
}

/// The Log In tab content: identifier field, password field, "Forgot?"
/// link, and primary action button.
///
/// This widget owns *form state only* (the `_formKey` and whether the
/// user has attempted a submit). Actual authentication is delegated to
/// the [onSubmit] callback.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.onSubmit,
    this.onForgotTap,
  });

  /// `true` when auth succeeded (caller navigates away); `false` on failure.
  final Future<bool> Function(LoginSubmission) onSubmit;
  final VoidCallback? onForgotTap;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  static const _busyCooldown = Duration(seconds: 8);

  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  bool _buttonBusy = false;
  Timer? _busyTimer;

  @override
  void dispose() {
    _busyTimer?.cancel();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (_formKey.currentState?.validate() != true) return;
    if (_buttonBusy) return;

    setState(() => _buttonBusy = true);
    _busyTimer?.cancel();
    _busyTimer = Timer(_busyCooldown, () {
      if (mounted && _buttonBusy) {
        setState(() => _buttonBusy = false);
      }
    });

    final ok = await widget.onSubmit(
      LoginSubmission(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      ),
    );
    if (!ok) _clearButtonBusy();
  }

  void _clearButtonBusy() {
    _busyTimer?.cancel();
    _busyTimer = null;
    if (_buttonBusy && mounted) setState(() => _buttonBusy = false);
  }

  String? _validateIdentifier(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Required';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('USERNAME OR EMAIL', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('login_identifier_field'),
            controller: _identifierController,
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'trader@example.com',
              suffixIcon: Icon(Icons.alternate_email),
            ),
            validator: _validateIdentifier,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PASSWORD', style: AppTypography.label),
              InkWell(
                onTap: widget.onForgotTap,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Text(
                    'FORGOT?',
                    style: AppTypography.microLabel.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('login_password_field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => unawaited(_submit()),
            decoration: InputDecoration(
              hintText: '••••••••',
              suffixIcon: AuthPasswordFieldSuffix(
                obscureText: _obscurePassword,
                visibilityToggleKey:
                    const ValueKey('login_password_visibility_toggle'),
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: AppSpacing.xl),
          NeonButton(
            key: const Key('login_submit_button'),
            label: _buttonBusy ? 'Logging in' : 'Log In',
            trailingIcon: Icons.login,
            onPressed: _buttonBusy ? null : () => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
