import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/personal_order.dart';
import 'confirmation_dialog.dart';
import 'neon_button.dart';

final _usd2 = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);

String _sideLabel(PersonalOrderSide s) {
  switch (s) {
    case PersonalOrderSide.buy:
      return 'Buy';
    case PersonalOrderSide.sell:
      return 'Sell';
  }
}

String _typeLabel(PersonalOrderType t) {
  switch (t) {
    case PersonalOrderType.limit:
      return 'Limit';
    case PersonalOrderType.market:
      return 'Market';
  }
}

String _statusLabel(PersonalOrderStatus s) {
  switch (s) {
    case PersonalOrderStatus.inQueue:
      return 'In queue';
    case PersonalOrderStatus.beingProcessed:
      return 'Being processed';
    case PersonalOrderStatus.resting:
      return 'Resting';
    case PersonalOrderStatus.filled:
      return 'Filled';
    case PersonalOrderStatus.cancelled:
      return 'Cancelled';
  }
}

/// Player’s active orders list (C6 mock).
class ActiveOrdersWidget extends StatelessWidget {
  const ActiveOrdersWidget({
    super.key,
    required this.orders,
    required this.onCancel,
  });

  final List<PersonalOrder> orders;
  final void Function(String orderId) onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Active orders',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (orders.isEmpty)
          Container(
            key: const ValueKey('active-orders-empty'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.outline),
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
          ...orders.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OrderRow(
                  order: o,
                  onCancel: onCancel,
                ),
              )),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onCancel});

  final PersonalOrder order;
  final void Function(String orderId) onCancel;

  @override
  Widget build(BuildContext context) {
    final canCancel = personalOrderCanCancel(order.status);
    final priceLine = order.orderType == PersonalOrderType.market
        ? '—'
        : _usd2.format(order.limitPrice ?? 0);

    return Container(
      key: ValueKey('active-order-${order.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_sideLabel(order.side)} · ${_typeLabel(order.orderType)} · '
                  '${order.quantity} @ $priceLine',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (canCancel)
                NeonButton(
                  key: ValueKey('active-order-cancel-${order.id}'),
                  label: 'Cancel',
                  variant: NeonButtonVariant.outlineDanger,
                  expand: false,
                  dense: true,
                  onPressed: () async {
                    final ok = await ConfirmationDialog.show(
                      context,
                      title: 'Cancel order?',
                      message: 'This removes your resting order from the book.',
                      confirmLabel: 'Cancel order',
                      cancelLabel: 'Keep',
                      destructive: true,
                    );
                    if (ok == true && context.mounted) {
                      onCancel(order.id);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _statusLabel(order.status),
            style: AppTypography.monoSmall.copyWith(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
