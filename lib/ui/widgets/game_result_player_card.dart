import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../screens/trading/trading_stat_format.dart';

/// One row in the **Results** stack (design `admin_game_trading_dashboard_9`).
class GameResultPlayerCard extends StatelessWidget {
  const GameResultPlayerCard({
    super.key,
    required this.displayName,
    required this.avatarInitials,
    required this.deltaCash,
    required this.deltaEnvelopes,
    required this.pnl,
    this.highlightBorder = false,
  });

  final String displayName;
  final String avatarInitials;
  final double deltaCash;
  final double deltaEnvelopes;

  /// `null` until the backend commits an envelope snapshot.
  final double? pnl;
  final bool highlightBorder;

  Color _pnlColor() {
    final p = pnl;
    if (p == null) return AppColors.textTertiary;
    const eps = 1e-9;
    if (p > eps) return AppColors.primary;
    if (p < -eps) return AppColors.secondary;
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        avatarInitials.trim().isEmpty ? '?' : avatarInitials.trim();

    final borderCol =
        highlightBorder ? AppColors.primary.withValues(alpha: 0.3) : AppColors.outline;

    final avatarBg =
        highlightBorder ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceContainerHigh;
    final avatarFg =
        highlightBorder ? AppColors.primary : AppColors.textSecondary;

    return Container(
      key: ValueKey('game-result-player-$displayName'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderCol),
        boxShadow: highlightBorder
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.outlineSubtle),
              ),
              color:
                  highlightBorder ? Colors.white.withValues(alpha: 0.02) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    initials,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: AppTypography.monoSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: avatarFg,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    displayName,
                    style: AppTypography.monoSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(child: _col('DELTA CASH', formatTradingDeltaCash(deltaCash))),
                _vDiv(),
                Expanded(
                  child:
                      _col('DELTA ENV', formatTradingDeltaEnvelopes(deltaEnvelopes)),
                ),
                _vDiv(),
                Expanded(
                  child: _col(
                    'PNL',
                    formatResultsPnlPlaceholder(pnl),
                    valueColor: _pnlColor(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _vDiv() => Container(
        width: 1,
        height: 44,
        color: AppColors.outlineSubtle,
      );

  static Widget _col(
    String label,
    String value, {
    Color? valueColor,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.microLabel.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppTypography.monoSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      );
}
