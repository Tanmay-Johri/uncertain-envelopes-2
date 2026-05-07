import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/neon_button.dart';

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

  final ValueChanged<LoginSubmission> onSubmit;
  final VoidCallback? onForgotTap;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (_formKey.currentState?.validate() != true) return;
    widget.onSubmit(
      LoginSubmission(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      ),
    );
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
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: '••••••••',
              suffixIcon: Icon(Icons.lock_outline),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: AppSpacing.xl),
          NeonButton(
            key: const Key('login_submit_button'),
            label: 'Log In',
            trailingIcon: Icons.login,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
