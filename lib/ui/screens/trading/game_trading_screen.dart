import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/stat_tile.dart';
import 'order_book_widget.dart';
import 'trading_stat_format.dart';
import 'trading_view_data.dart';

/// Trading dashboard (C6). Layout follows
/// `design-uncertain-envelopes-2/admin_game_trading_dashboard_7/code.html`.
class GameTradingScreen extends StatelessWidget {
  const GameTradingScreen({
    super.key,
    required this.data,
    this.onShowLogs,
    this.onEndGameFromMenu,
    this.onAddTime,
  });

  final GameTradingViewData data;
  final VoidCallback? onShowLogs;
  final VoidCallback? onEndGameFromMenu;
  final VoidCallback? onAddTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('game-trading-scaffold'),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: _TradingWindowHeader(
              isViewerAdmin: data.isViewerAdmin,
              onShowLogs: onShowLogs,
              onEndGameFromMenu: onEndGameFromMenu,
              onAccountTap: () => context.go(AppRoutes.profile),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      data.gameTitle,
                      key: const ValueKey('game-trading-title'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionHeader.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      data.description,
                      key: const ValueKey('game-trading-description'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (data.isTimed &&
                            data.tradingTimeRemaining != null) ...[
                          CountdownTimer(
                            key: const ValueKey('game-trading-countdown'),
                            initialRemaining: data.tradingTimeRemaining!,
                            textStyle: AppTypography.timerDisplay,
                          ),
                          if (data.isViewerAdmin) ...[
                            const SizedBox(width: AppSpacing.md),
                            _AddTimeButton(onPressed: onAddTime),
                          ],
                        ],
                      ],
                    ),
                    if (data.isTimed && data.tradingTimeRemaining != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'TIME REMAINING',
                          key: const ValueKey('game-trading-time-label'),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StatTile(
                            key: const ValueKey('trading-stat-delta-cash'),
                            label: 'Delta Cash',
                            value: formatTradingDeltaCash(data.deltaCash),
                            signedValue: data.deltaCash,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StatTile(
                            key: const ValueKey('trading-stat-delta-envelopes'),
                            label: 'Delta Envelopes',
                            value: formatTradingDeltaEnvelopes(
                              data.deltaEnvelopes,
                            ),
                            signedValue: data.deltaEnvelopes,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OrderBookWidget(
                      key: const ValueKey('trading-orderbook-section'),
                      bids: data.orderBookBids,
                      asks: data.orderBookAsks,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionPlaceholder(
                      key: const ValueKey('trading-chart-section'),
                      label: 'Price chart (coming in C6)',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionPlaceholder(
                      key: const ValueKey('trading-pnl-section'),
                      label: 'PnL calculator (coming in C6)',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SectionPlaceholder(
                      key: const ValueKey('trading-active-orders-section'),
                      label: 'Active orders (coming in C6)',
                    ),
                    const SizedBox(height: AppSpacing.xxxxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky frosted header: account (left), `TRADING WINDOW` (center), overflow (right).
class _TradingWindowHeader extends StatelessWidget {
  const _TradingWindowHeader({
    required this.isViewerAdmin,
    required this.onAccountTap,
    this.onShowLogs,
    this.onEndGameFromMenu,
  });

  final bool isViewerAdmin;
  final VoidCallback onAccountTap;
  final VoidCallback? onShowLogs;
  final VoidCallback? onEndGameFromMenu;

  /// Content row only; padding is added outside this height.
  static const double _toolbarHeight = 36;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.95),
            border: const Border(
              bottom: BorderSide(color: AppColors.outlineSubtle),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: SizedBox(
            height: _toolbarHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'TRADING WINDOW',
                  key: const ValueKey('game-trading-appbar-title'),
                  style: AppTypography.tradingWindowHeaderTitle.copyWith(
                    fontSize: 12,
                    height: 1.0,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: _toolbarHeight,
                      ),
                      icon: Icon(
                        Icons.account_circle_outlined,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                      tooltip: 'Profile',
                      onPressed: onAccountTap,
                    ),
                    if (isViewerAdmin)
                      PopupMenuButton<String>(
                        key: const ValueKey('game-trading-admin-menu'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: _toolbarHeight,
                        ),
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'logs':
                              onShowLogs?.call();
                            case 'end':
                              onEndGameFromMenu?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'logs',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.terminal,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Show Logs',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'end',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.stop_circle_outlined,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'End Game',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(width: 36),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTimeButton extends StatelessWidget {
  const _AddTimeButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.outlineSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('game-trading-add-time'),
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.add,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.monoSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
