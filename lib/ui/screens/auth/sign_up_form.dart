import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/neon_button.dart';
import 'auth_password_field_suffix.dart';

/// Credentials collected by the sign-up form.
class SignUpSubmission {
  const SignUpSubmission({
    required this.username,
    required this.email,
    required this.password,
  });

  /// Normalised to lowercase for uniqueness (matches PRD players.username).
  final String username;
  final String email;
  final String password;
}

/// The Sign Up tab content: username, email, password, and submit.
///
/// Validation rules here intentionally mirror the PRD + stream-A
/// server-side constraints so the client rejects bad inputs before we
/// spend a round trip:
///
/// - Username: 3–32 chars, alphanumeric + `_-`.
/// - Email: non-empty, matches a conservative email pattern.
/// - Password: min 8 chars.
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key, required this.onSubmit});

  /// `true` when auth succeeded (caller navigates away); `false` on failure.
  final Future<bool> Function(SignUpSubmission) onSubmit;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  static const _busyCooldown = Duration(seconds: 8);

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _obscurePassword = true;
  bool _buttonBusy = false;
  Timer? _busyTimer;

  // Kept intentionally simple: exactly one `@` with something on each
  // side and a `.` in the domain. Full RFC-compliant validation lives
  // server-side.
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernameRegex = RegExp(r'^[A-Za-z0-9_-]+$');

  @override
  void dispose() {
    _busyTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
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
      SignUpSubmission(
        username: _usernameController.text.trim().toLowerCase(),
        email: _emailController.text.trim(),
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

  String? _validateUsername(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Required';
    if (trimmed.length < AppConstants.minUsernameLength) {
      return 'At least ${AppConstants.minUsernameLength} characters';
    }
    if (trimmed.length > AppConstants.maxUsernameLength) {
      return 'At most ${AppConstants.maxUsernameLength} characters';
    }
    if (!_usernameRegex.hasMatch(trimmed)) {
      return 'Letters, numbers, _ or - only';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Required';
    if (!_emailRegex.hasMatch(trimmed)) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length < AppConstants.minPasswordLength) {
      return 'At least ${AppConstants.minPasswordLength} characters';
    }
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
          Text('USERNAME', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('signup_username_field'),
            controller: _usernameController,
            autofillHints: const [AutofillHints.newUsername],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Choose a username',
              suffixIcon: Icon(Icons.person_outline),
            ),
            validator: _validateUsername,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('EMAIL', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('signup_email_field'),
            controller: _emailController,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'trader@example.com',
              suffixIcon: Icon(Icons.mail_outline),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('PASSWORD', style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: const Key('signup_password_field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => unawaited(_submit()),
            decoration: InputDecoration(
              hintText: 'Create a strong password',
              suffixIcon: AuthPasswordFieldSuffix(
                obscureText: _obscurePassword,
                visibilityToggleKey:
                    const ValueKey('signup_password_visibility_toggle'),
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: AppSpacing.xl),
          NeonButton(
            key: const Key('signup_submit_button'),
            label: _buttonBusy ? 'Signing up' : 'Sign Up',
            trailingIcon: Icons.arrow_forward,
            onPressed: _buttonBusy ? null : () => unawaited(_submit()),
          ),
        ],
      ),
    );
  }
}
