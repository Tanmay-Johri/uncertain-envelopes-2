import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

final _orderBookPriceFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);

String formatOrderBookPrice(double price) => _orderBookPriceFormat.format(price);

enum OrderBookSide { bid, ask }

/// One bid or ask line with optional depth visualization (`dashboard_7` order book).
class OrderBookRow extends StatelessWidget {
  const OrderBookRow({
    super.key,
    required this.side,
    required this.quantity,
    required this.price,
    required this.depth,
    this.onTap,
  });

  final OrderBookSide side;
  final int quantity;
  final double price;

  /// 0–1 fraction for depth bar width; values are clamped.
  final double depth;
  final VoidCallback? onTap;

  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 8,
  );

  @override
  Widget build(BuildContext context) {
    final d = depth.clamp(0.0, 1.0);
    final priceColor = switch (side) {
      OrderBookSide.bid => AppColors.primary,
      OrderBookSide.ask => AppColors.secondary,
    };
    final barColor = switch (side) {
      OrderBookSide.bid => AppColors.primary.withValues(alpha: 0.1),
      OrderBookSide.ask => AppColors.secondary.withValues(alpha: 0.1),
    };
    final alignment = switch (side) {
      OrderBookSide.bid => Alignment.centerLeft,
      OrderBookSide.ask => Alignment.centerRight,
    };

    final row = Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: FractionallySizedBox(
              widthFactor: d,
              alignment: alignment,
              child: ColoredBox(color: barColor),
            ),
          ),
        ),
        Padding(
          padding: _padding,
          child: Row(
            children: switch (side) {
              OrderBookSide.bid => [
                  Expanded(
                    child: Text(
                      '$quantity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      formatOrderBookPrice(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: priceColor,
                      ),
                    ),
                  ),
                ],
              OrderBookSide.ask => [
                  Expanded(
                    child: Text(
                      formatOrderBookPrice(price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: priceColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
            },
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: row,
      ),
    );
  }
}
