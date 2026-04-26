import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/personal_order.dart';
import '../../core/trading/usd_limit_price_display.dart';
import 'confirmation_dialog.dart';

final _createdFmt = DateFormat.jm();

/// Side/type pill (`SELL MARKET` is the longest label at this typography).
const _kSideTypePillWidth = 108.0;

String _sideTypePill(PersonalOrderSide side, PersonalOrderType type) {
  final s = switch (side) {
    PersonalOrderSide.buy => 'BUY',
    PersonalOrderSide.sell => 'SELL',
  };
  final t = switch (type) {
    PersonalOrderType.limit => 'LIMIT',
    PersonalOrderType.market => 'MARKET',
  };
  return '$s $t';
}

/// PRD `orders.status` snake_case for the chip.
String _statusChipText(PersonalOrderStatus s) {
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

/// Active orders — layout from `admin_game_trading_dashboard_7/code.html`,
/// details from PRD `orders` (no **order_id** in UI).
class ActiveOrdersWidget extends StatelessWidget {
  const ActiveOrdersWidget({
    super.key,
    required this.orders,
    required this.pendingCancellationOrderIds,
    required this.onCancellationRequested,
  });

  final List<PersonalOrder> orders;

  /// Client-side: cancellation command sent; waiting for `cancelled` from backend.
  final Set<String> pendingCancellationOrderIds;

  /// User confirmed the dialog; parent sends `cancel_order` and owns ack / timeout UX.
  final void Function(BuildContext context, String orderId)
      onCancellationRequested;

  @override
  Widget build(BuildContext context) {
    final displayOrders = personalOrdersSortedNewestFirst(orders);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Active Orders',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              shadows: const [
                Shadow(
                  color: Color(0x40000000),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (displayOrders.isEmpty)
          Container(
            key: const ValueKey('active-orders-empty'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.outlineSubtle),
            ),
            child: Text(
              'No active orders',
              textAlign: TextAlign.center,
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          )
        else
          ...displayOrders.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ActiveOrderCard(
                    order: e.value,
                    initiallyExpanded: e.key == 0,
                    pendingCancellationOrderIds: pendingCancellationOrderIds,
                    onCancellationRequested: onCancellationRequested,
                  ),
                ),
              ),
      ],
    );
  }
}

class _ActiveOrderCard extends StatefulWidget {
  const _ActiveOrderCard({
    required this.order,
    required this.initiallyExpanded,
    required this.pendingCancellationOrderIds,
    required this.onCancellationRequested,
  });

  final PersonalOrder order;
  final bool initiallyExpanded;
  final Set<String> pendingCancellationOrderIds;
  final void Function(BuildContext context, String orderId)
      onCancellationRequested;

  @override
  State<_ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<_ActiveOrderCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _ActiveOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final isBuy = o.side == PersonalOrderSide.buy;
    final priceSuffix = o.orderType == PersonalOrderType.market
        ? 'Market'
        : formatUsdLimitForActiveOrder(o.limitPrice ?? 0);
    final isCancelled = o.status == PersonalOrderStatus.cancelled;
    final isPending = widget.pendingCancellationOrderIds.contains(o.id);
    final canSendCancel = personalOrderCanCancel(o.status);

    final limitDetail = o.orderType == PersonalOrderType.market
        ? '—'
        : formatUsdLimitForActiveOrder(o.limitPrice ?? 0);
    final statusChip = personalOrderStatusChipStyle(o.status);

    return Container(
      key: ValueKey('active-order-${o.id}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              hoverColor: Colors.white.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: _kSideTypePillWidth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isBuy
                                      ? AppColors.primary
                                          .withValues(alpha: 0.1)
                                      : AppColors.secondary
                                          .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  _sideTypePill(o.side, o.orderType),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.microLabel.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: isBuy
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusChip.background,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    border:
                                        Border.all(color: statusChip.border),
                                  ),
                                  child: Text(
                                    _statusChipText(o.status),
                                    style: AppTypography.monoSmall.copyWith(
                                      fontSize: 10,
                                      color: statusChip.foreground,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.expand_more,
                                    size: 22,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${o.quantityCurrent} units @ $priceSuffix',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, thickness: 1, color: AppColors.outlineSubtle),
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
                    'Created: ${o.createdAt != null ? _createdFmt.format(o.createdAt!.toLocal()) : '—'}\n'
                    'Initial Qty: ${o.quantityInitial}\n'
                    'Current Qty: ${o.quantityCurrent}\n'
                    'Limit price: $limitDetail',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: ValueKey('active-order-cancel-${o.id}'),
                      onPressed: _cancelButtonEnabled(
                        isCancelled: isCancelled,
                        isPending: isPending,
                        canSendCancel: canSendCancel,
                      )
                          ? () async {
                              final ok = await ConfirmationDialog.show(
                                context,
                                title: '',
                                message:
                                    'Are you sure you want to send a cancellation request?',
                                confirmLabel: 'Cancel',
                                cancelLabel: 'Back',
                                destructive: true,
                                uppercaseActionLabels: false,
                              );
                              if (ok == true && context.mounted) {
                                widget.onCancellationRequested(context, o.id);
                              }
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        disabledForegroundColor:
                            AppColors.textDisabled.withValues(alpha: 0.55),
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        _cancelButtonLabel(
                          isCancelled: isCancelled,
                          isPending: isPending,
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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

  static String _cancelButtonLabel({
    required bool isCancelled,
    required bool isPending,
  }) {
    if (isCancelled) return 'Cancelled';
    if (isPending) return 'Cancelling';
    return 'Cancel Order';
  }

  static bool _cancelButtonEnabled({
    required bool isCancelled,
    required bool isPending,
    required bool canSendCancel,
  }) {
    if (isCancelled || isPending) return false;
    return canSendCancel;
  }
}
