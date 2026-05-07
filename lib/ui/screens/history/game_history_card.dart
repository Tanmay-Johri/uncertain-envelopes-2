import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../trading/trading_stat_format.dart';
import 'game_history_view_data.dart';

/// Accordion card for one completed game in the history list.
///
/// Fully stateless — the caller owns [isExpanded] and supplies [onTap].
class GameHistoryCard extends StatelessWidget {
  const GameHistoryCard({
    super.key,
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  final GameHistoryEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(entry: entry, isExpanded: isExpanded, onTap: onTap),
          if (isExpanded) _ExpandedBody(entry: entry),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header row (always visible)
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
  });

  final GameHistoryEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pnlColor = _pnlColor(entry.viewerPnl);
    final pnlText = formatTradingDeltaCash(entry.viewerPnl);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: isExpanded
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.outlineSubtle),
                ),
                color: Color(0x0DFFFFFF), // white/5
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // PnL + chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pnlText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: pnlColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded body
// ---------------------------------------------------------------------------

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.entry});

  final GameHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final envelopeText = entry.envelopePriceUsd != null
        ? '\$${entry.envelopePriceUsd!.toStringAsFixed(2)}'
        : kUnsetUsdLine;

    return Container(
      color: Colors.black.withValues(alpha: 0.2),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata grid
          Row(
            children: [
              Expanded(
                child: _MetaCell(
                  label: 'SECURITY TYPE',
                  value: entry.securityType,
                ),
              ),
              Expanded(
                child: _MetaCell(
                  label: 'STATUS',
                  value: entry.isRanked ? 'Ranked' : 'Casual',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetaCell(
                  label: 'ADMIN',
                  value: '@${entry.adminName}',
                ),
              ),
              Expanded(
                child: _MetaCell(
                  label: 'ENVELOPE PRICE',
                  value: envelopeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetaCell(
                  label: 'STARTED',
                  value: _formatDateTime(entry.startedAt),
                ),
              ),
              Expanded(
                child: _MetaCell(
                  label: 'ENDED',
                  value: _formatDateTime(entry.endedAt),
                ),
              ),
            ],
          ),

          // Players PNL section
          if (entry.playerResults.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.outline, height: 1),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'PLAYERS PNL',
              style: AppTypography.microLabel.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...entry.playerResults.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlayerPnlRow(result: r),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.microLabel.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PlayerPnlRow extends StatelessWidget {
  const _PlayerPnlRow({required this.result});

  final GameHistoryPlayerResult result;

  @override
  Widget build(BuildContext context) {
    final pnlText = formatTradingDeltaCash(result.pnl);
    final pnlColor = _pnlColor(result.pnl);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineSubtle),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              result.displayName,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            pnlText,
            style: AppTypography.bodySmall.copyWith(
              color: pnlColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _dtFormat = DateFormat('MMM d, HH:mm');

/// Returns a formatted date/time string, or "—" when [dt] is null.
String _formatDateTime(DateTime? dt) =>
    dt != null ? _dtFormat.format(dt) : '—';

Color _pnlColor(double pnl) {
  if (pnl > 0) return AppColors.primary;
  if (pnl < 0) return AppColors.secondary;
  return AppColors.textPrimary;
}
