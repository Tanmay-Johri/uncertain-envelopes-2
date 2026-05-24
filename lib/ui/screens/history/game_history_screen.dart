import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import 'game_history_card.dart';
import 'game_history_view_data.dart';

/// Game History screen (**C10**).
///
/// Ref: `design-uncertain-envelopes-2/admin_game_trading_dashboard_6/code.html`.
///
/// Displays past games as an accordion list. Multiple cards can be expanded
/// simultaneously (multi-expand). Each card is keyed by [GameHistoryEntry.id]
/// so expand state survives scroll.
class GameHistoryScreen extends StatefulWidget {
  const GameHistoryScreen({
    super.key,
    required this.entries,
    this.onShowLogsForGame,
  });

  final List<GameHistoryEntry> entries;

  /// Opens the transaction log for [gameId] (wired by route / mocks).
  final void Function(String gameId)? onShowLogsForGame;

  @override
  State<GameHistoryScreen> createState() => _GameHistoryScreenState();
}

class _GameHistoryScreenState extends State<GameHistoryScreen> {
  /// Ids of currently expanded cards. Multi-expand: any subset can be open.
  final Set<String> _expandedIds = {};

  void _toggle(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _branchNav(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.create);
      case 2:
        context.go(AppRoutes.orders);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('game-history-scaffold'),
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
          const _HistoryHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              child: widget.entries.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        top: AppSpacing.lg,
                        bottom: AppSpacing.sectionGap + 96,
                      ),
                      itemCount: widget.entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final entry = widget.entries[index];
                        return GameHistoryCard(
                          key: ValueKey('history-card-${entry.id}'),
                          entry: entry,
                          isExpanded: _expandedIds.contains(entry.id),
                          onTap: () => _toggle(entry.id),
                          onShowLogs: widget.onShowLogsForGame == null
                              ? null
                              : () => widget.onShowLogsForGame!(entry.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

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
                      tooltip: 'Back to profile',
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => context.go(AppRoutes.profile),
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'NO GAME HISTORY',
              style: AppTypography.label.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Completed games will appear here.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
