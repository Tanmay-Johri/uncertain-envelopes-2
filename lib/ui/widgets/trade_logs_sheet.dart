import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../screens/trading/trading_stat_format.dart';
import '../screens/trading/trading_view_data.dart';

/// Bottom sheet listing every executed trade:
/// `Seller ——(qty @ $price)——→ Buyer`
class TradeLogsSheet extends StatefulWidget {
  const TradeLogsSheet({
    super.key,
    required this.logs,
    required this.viewerPlayerId,
  });

  final List<TradeLogEntry> logs;
  final String viewerPlayerId;

  static Future<void> show(
    BuildContext context, {
    required List<TradeLogEntry> logs,
    required String viewerPlayerId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TradeLogsSheet(
        logs: logs,
        viewerPlayerId: viewerPlayerId,
      ),
    );
  }

  @override
  State<TradeLogsSheet> createState() => _TradeLogsSheetState();
}

class _TradeLogsSheetState extends State<TradeLogsSheet> {
  var _onlyMine = false;

  List<TradeLogEntry> get _displayLogs => _onlyMine
      ? widget.logs
          .where((e) => tradeLogEntryInvolvesPlayer(e, widget.viewerPlayerId))
          .toList()
      : widget.logs;

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    final displayLogs = _displayLogs;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'TRANSACTION LOG',
                    style: AppTypography.microLabel.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (logs.isNotEmpty) ...[
                  Text(
                    'My transactions',
                    style: AppTypography.microLabel.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Switch(
                    key: const ValueKey('trade-logs-only-mine-toggle'),
                    value: _onlyMine,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    inactiveThumbColor: AppColors.textSecondary,
                    inactiveTrackColor: AppColors.surfaceContainerHigh,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => setState(() => _onlyMine = v),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.outlineSubtle, height: 1),
          if (logs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TIME',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'SELLER',
                      textAlign: TextAlign.right,
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Expanded(flex: 4, child: SizedBox()),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'BUYER',
                      style: AppTypography.microLabel.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'No transactions yet',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (displayLogs.isEmpty)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text(
                    'No matching transactions',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                key: const ValueKey('trade-logs-list'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                itemCount: displayLogs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) =>
                    _TradeLogRow(entry: displayLogs[index]),
              ),
            ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSpacing.md),
        ],
      ),
    );
  }
}

class _TradeLogRow extends StatelessWidget {
  const _TradeLogRow({required this.entry});

  final TradeLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final priceText =
        '\$${entry.price % 1 == 0 ? entry.price.toInt() : entry.price.toStringAsFixed(2)}';
    final annotation = '${entry.quantity} @ $priceText';

    final localeName = Localizations.localeOf(context).toString();
    final timeLabel = entry.tradedAt != null
        ? formatTradeLogTime(entry.tradedAt!, localeName: localeName)
        : '--:--';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            timeLabel,
            style: AppTypography.microLabel.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            entry.sellerName,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                annotation,
                style: AppTypography.microLabel.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.outlineSubtle,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Text(
            entry.buyerName,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
