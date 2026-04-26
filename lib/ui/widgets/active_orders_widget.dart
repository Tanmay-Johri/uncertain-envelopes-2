import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/personal_order.dart';
import 'confirmation_dialog.dart';

final _usd2 = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);

final _createdFmt = DateFormat.jm();

/// Status chip: `border-blue-500/30 text-blue-400 bg-blue-500/10` (dashboard 7).
const _statusChipFg = Color(0xFF60A5FA);
const _statusChipBorder = Color(0x4D3B82F6);
const _statusChipBg = Color(0x1A3B82F6);

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

/// Lowercase snake_case chip label to match `code.html` (`in_queue`, `open`, …).
String _statusChipText(PersonalOrderStatus s) {
  return switch (s) {
    PersonalOrderStatus.inQueue => 'in_queue',
    PersonalOrderStatus.beingProcessed => 'being_processed',
    PersonalOrderStatus.resting => 'open',
    PersonalOrderStatus.filled => 'filled',
    PersonalOrderStatus.cancelled => 'cancelled',
  };
}

/// Short stable **#** id for the **ID:** row (mock).
String _displayIdSuffix(String id) {
  final digits = RegExp(r'\d+')
      .allMatches(id)
      .map((m) => m.group(0)!)
      .join();
  if (digits.length >= 6) {
    return digits.substring(digits.length - 6);
  }
  final n = id.hashCode.abs() % 1000000;
  return n.toString().padLeft(6, '0');
}

/// Active orders — layout from `admin_game_trading_dashboard_7/code.html`.
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
        if (orders.isEmpty)
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
          ...orders.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ActiveOrderCard(
                    order: e.value,
                    initiallyExpanded: e.key == 0,
                    onCancel: onCancel,
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
    required this.onCancel,
  });

  final PersonalOrder order;
  final bool initiallyExpanded;
  final void Function(String orderId) onCancel;

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
        : _usd2.format(o.limitPrice ?? 0);
    final canCancel = personalOrderCanCancel(o.status);

    return Container(
      key: ValueKey('active-order-${o.id}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
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
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
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
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  '${o.quantity} Units',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
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
                                    color: _statusChipBg,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: _statusChipBorder),
                                  ),
                                  child: Text(
                                    _statusChipText(o.status),
                                    style: AppTypography.monoSmall.copyWith(
                                      fontSize: 10,
                                      color: _statusChipFg,
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
                      '@ $priceSuffix',
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
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'ID: #${_displayIdSuffix(o.id)}\n'
                      'Created: ${o.createdAt != null ? _createdFmt.format(o.createdAt!.toLocal()) : '—'}\n'
                      'Initial Qty: ${o.quantity}',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  if (canCancel) ...[
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      key: ValueKey('active-order-cancel-${o.id}'),
                      onPressed: () async {
                        final ok = await ConfirmationDialog.show(
                          context,
                          title: 'Cancel order?',
                          message:
                              'This removes your resting order from the book.',
                          confirmLabel: 'Cancel order',
                          cancelLabel: 'Keep',
                          destructive: true,
                        );
                        if (ok == true && context.mounted) {
                          widget.onCancel(o.id);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      label: Text(
                        'Cancel Order',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
