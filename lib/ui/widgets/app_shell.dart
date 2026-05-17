import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_bottom_navigation_bar.dart';
import 'uncertain_envelopes_logo_mark.dart';

/// One of the three destinations reachable from the bottom nav.
///
/// The order here defines the visual order in the bar.
enum AppNavDestination { home, create, orders }

/// The shared shell for all bottom-nav screens.
///
/// Responsibilities:
/// - Paint the sticky blurred brand mark header with an
///   account icon on the right.
/// - Host the child route body.
/// - Render the three-tab bottom navigation and surface taps.
///
/// [AppShell] does not own navigation. The owning GoRouter shell route
/// passes [currentIndex] and an [onDestinationSelected] callback.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onAccountTap,
  });

  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAccountTap;

  /// Toolbar row height below the status bar (content only).
  static const double headerHeight = 56;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final totalHeaderHeight = topInset + headerHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      // When true, shell bodies paint under the header; BackdropFilter then
      // blurs that content (e.g. white screen titles), which reads as ghost
      // text behind the brand mark. Keep the body below the app bar instead.
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(totalHeaderHeight),
        child: _FrostedHeader(
          onAccountTap: onAccountTap,
          totalHeight: totalHeaderHeight,
        ),
      ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onDestinationSelected,
      ),
    );
  }
}

class _FrostedHeader extends StatelessWidget {
  const _FrostedHeader({
    required this.onAccountTap,
    required this.totalHeight,
  });

  final VoidCallback onAccountTap;
  final double totalHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: totalHeight,
          color: AppColors.background.withValues(alpha: 0.72),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: AppShell.headerHeight,
            child: Row(
              children: [
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: UncertainEnvelopesLogoMark(
                      height: 22,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.account_circle_outlined,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Profile',
                  onPressed: onAccountTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

