import 'package:flutter/material.dart';

/// Lock icon plus visibility toggle for auth password [TextFormField]s.
class AuthPasswordFieldSuffix extends StatelessWidget {
  const AuthPasswordFieldSuffix({
    super.key,
    required this.obscureText,
    required this.onToggle,
    required this.visibilityToggleKey,
  });

  final bool obscureText;
  final VoidCallback onToggle;
  final Key visibilityToggleKey;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 2),
          child: Icon(Icons.lock_outline, size: 22, color: iconColor),
        ),
        IconButton(
          key: visibilityToggleKey,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          tooltip: obscureText ? 'Show password' : 'Hide password',
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 22,
            color: iconColor,
          ),
        ),
      ],
    );
  }
}
