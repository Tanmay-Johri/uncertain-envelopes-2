import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Shared three-tab bar: **Home**, **Create**, **Orders** — same chrome as
/// [AppShell], reusable on full-screen routes (e.g. game results).
class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.visualSelectionEnabled = true,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// When false (e.g. game routes outside the shell), both selected and
  /// unselected items use tertiary — no tab picks up primary green.
  final bool visualSelectionEnabled;

  @override
  Widget build(BuildContext context) {
    final accent =
        visualSelectionEnabled ? AppColors.primary : AppColors.textTertiary;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      selectedItemColor: accent,
      unselectedItemColor: AppColors.textTertiary,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'HOME',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          activeIcon: Icon(Icons.add_circle),
          label: 'CREATE',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'ORDERS',
        ),
      ],
    );
  }
}
