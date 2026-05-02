import 'package:flutter/material.dart';

import '../../core/formatting/order_created_at_display.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/personal_order.dart';
import '../../core/trading/usd_limit_price_display.dart';
import 'confirmation_dialog.dart';

/// PRD `orders.status` snake_case (matches active-order chip vocabulary).
String _pendingOrderStatusLine(PersonalOrderStatus s) {
  return switch (s) {
    PersonalOrderStatus.inQueue => 'in_queue',
    PersonalOrderStatus.beingProcessed => 'being_processed',
    PersonalOrderStatus.resting => 'order_resting',
    PersonalOrderStatus.filled => 'order_closed',
    PersonalOrderStatus.cancelled => 'cancelled',
    PersonalOrderStatus.rejected => 'rejected',
    PersonalOrderStatus.gameEnded => 'game_ended',
  };
}

/// e.g. `buy limit`, `sell market` (matches requested copy).
String _pendingOrderSideTypePhrase(
  PersonalOrderSide side,
  PersonalOrderType type,
) {
  final s = switch (side) {
    PersonalOrderSide.buy => 'buy',
    PersonalOrderSide.sell => 'sell',
  };
  final t = switch (type) {
    PersonalOrderType.limit => 'limit',
    PersonalOrderType.market => 'market',
  };
  return '$s $t';
}

/// One expandable row on the **Pending Orders** screen (plan **C9**).
class PendingOrderCard extends StatefulWidget {
  const PendingOrderCard({
    super.key,
    required this.gameTitle,
    required this.gameDescription,
    required this.order,
    this.onCancelRequested,
  });

  final String gameTitle;
  final String gameDescription;
  final PersonalOrder order;

  /// Stream C stub; only called after confirm dialog when cancel is allowed.
  final void Function(String orderId)? onCancelRequested;

  @override
  State<PendingOrderCard> createState() => _PendingOrderCardState();
}

class _PendingOrderCardState extends State<PendingOrderCard> {
  var _expanded = false;

  Color _headlinePriceColor() {
    final o = widget.order;
    if (o.orderType == PersonalOrderType.market) {
      return AppColors.textSecondary;
    }
    if (o.side == PersonalOrderSide.buy) {
      return AppColors.primary;
    }
    return AppColors.secondary;
  }

  String _headlinePriceText() {
    final o = widget.order;
    if (o.orderType == PersonalOrderType.market) {
      return '—';
    }
    return formatUsdLimitForActiveOrder(o.limitPrice ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final isBuy = o.side == PersonalOrderSide.buy;
    final canCancel = personalOrderCanCancel(o.status);

    return AnimatedContainer(
      key: ValueKey('pending-order-card-${o.id}'),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.22)
              : AppColors.outline,
          width: 1,
        ),
        boxShadow: _expanded
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.gameTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${o.quantityCurrent}',
                            style: AppTypography.monoSmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _headlinePriceText(),
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _headlinePriceColor(),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isBuy
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isBuy
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.secondary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                isBuy ? 'Buy' : 'Sell',
                                style: AppTypography.microLabel.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.35,
                                  color: isBuy
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            size: 22,
                            color: _expanded
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.outline.withValues(alpha: 0.09),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.gameDescription,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Created: ${o.createdAt != null ? formatOrderCreatedUtcForUi(context, o.createdAt!) : '—'}\n'
                    'Initial Qty: ${o.quantityInitial}\n'
                    'Current Qty: ${o.quantityCurrent}\n'
                    'Limit price: ${o.orderType == PersonalOrderType.market ? '—' : formatUsdLimitForActiveOrder(o.limitPrice ?? 0)}\n'
                    'Order status: ${_pendingOrderStatusLine(o.status)}\n'
                    'Type: ${_pendingOrderSideTypePhrase(o.side, o.orderType)}',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      key: ValueKey('pending-order-cancel-${o.id}'),
                      onPressed: canCancel
                          ? () async {
                              final ok = await ConfirmationDialog.show(
                                context,
                                title: '',
                                message:
                                    'Cancel this order for ${widget.gameTitle}?',
                                confirmLabel: 'Cancel',
                                cancelLabel: 'Back',
                                destructive: true,
                                uppercaseActionLabels: false,
                              );
                              if (ok == true && context.mounted) {
                                widget.onCancelRequested?.call(o.id);
                              }
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        disabledForegroundColor:
                            AppColors.textDisabled.withValues(alpha: 0.5),
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        'Cancel Order',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
