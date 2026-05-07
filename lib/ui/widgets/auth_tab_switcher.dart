import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Two-mode selector used at the top of the auth card.
enum AuthTab { logIn, signUp }

/// A two-tab horizontal row for toggling between the Log In and Sign
/// Up forms. Matches the design-system spec: selected tab shows the
/// primary green underline + faint primary background; unselected tab
/// is slate with a hover tint (not replicated here — Flutter has its
/// own ripple).
class AuthTabSwitcher extends StatelessWidget {
  const AuthTabSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AuthTab selected;
  final ValueChanged<AuthTab> onChanged;

  static const double barHeight = 52;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthTab(
              label: 'Log In',
              active: selected == AuthTab.logIn,
              onTap: () => onChanged(AuthTab.logIn),
            ),
          ),
          Expanded(
            child: _AuthTab(
              label: 'Sign Up',
              active: selected == AuthTab.signUp,
              onTap: () => onChanged(AuthTab.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = active
        ? AppColors.primary.withValues(alpha: 0.10)
        : Colors.transparent;
    final foreground = active ? AppColors.primary : AppColors.textTertiary;
    final underline = active ? AppColors.primary : Colors.transparent;

    return Material(
      color: background,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AuthTabSwitcher.barHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: underline, width: 2),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.label.copyWith(color: foreground),
          ),
        ),
      ),
    );
  }
}
