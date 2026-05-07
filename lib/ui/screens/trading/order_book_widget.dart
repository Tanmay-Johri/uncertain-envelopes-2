import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/order_book_row.dart';
import 'trading_view_data.dart';

/// Order book panel matching `admin_game_trading_dashboard_7` (split bid / ask).
class OrderBookWidget extends StatelessWidget {
  const OrderBookWidget({
    super.key,
    required this.bids,
    required this.asks,
    this.height = 256,
  });

  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;

  /// Total control height including header (`h-64` in mock ≈ 256).
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxBidQty = bids.isEmpty
        ? 0
        : bids.map((e) => e.quantity).reduce(math.max);
    final maxAskQty = asks.isEmpty
        ? 0
        : asks.map((e) => e.quantity).reduce(math.max);
    final bidDen = maxBidQty > 0 ? maxBidQty : 1;
    final askDen = maxAskQty > 0 ? maxAskQty : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Order Book',
            style: AppTypography.bodySmall.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          type: MaterialType.canvas,
          color: AppColors.surfaceContainerLow,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.outline),
          ),
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const _OrderBookHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final b in bids)
                                  OrderBookRow(
                                    side: OrderBookSide.bid,
                                    quantity: b.quantity,
                                    price: b.price,
                                    depth: b.quantity / bidDen,
                                  ),
                              ],
                            ),
                          ),
                          Container(width: 1, color: AppColors.outline),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final a in asks)
                                  OrderBookRow(
                                    side: OrderBookSide.ask,
                                    quantity: a.quantity,
                                    price: a.price,
                                    depth: a.quantity / askDen,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderBookHeader extends StatelessWidget {
  const _OrderBookHeader();

  @override
  Widget build(BuildContext context) {
    final topRadius = Radius.circular(AppRadius.lg);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.only(
          topLeft: topRadius,
          topRight: topRadius,
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.outline),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.outline),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Qty',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    'Bid',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ask',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    'Qty',
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
