import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/personal_order.dart';
import 'neon_button.dart';

/// C6 mock: create order dialog. Returns a [PersonalOrder] with a placeholder
/// [PersonalOrder.id] (`new`) — the screen assigns a real id.
class NewOrderModal extends StatefulWidget {
  const NewOrderModal({super.key, required this.marketPrice});

  final double marketPrice;

  static Future<PersonalOrder?> show(
    BuildContext context, {
    required double marketPrice,
  }) {
    return showDialog<PersonalOrder>(
      context: context,
      barrierDismissible: true,
      builder: (_) => NewOrderModal(marketPrice: marketPrice),
    );
  }

  @override
  State<NewOrderModal> createState() => _NewOrderModalState();
}

class _NewOrderModalState extends State<NewOrderModal> {
  PersonalOrderSide _side = PersonalOrderSide.buy;
  PersonalOrderType _type = PersonalOrderType.limit;
  final _qtyCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      return;
    }
    double? limit;
    if (_type == PersonalOrderType.limit) {
      limit = double.tryParse(_limitCtrl.text.trim());
      if (limit == null || limit <= 0) {
        return;
      }
    }
    final status = _type == PersonalOrderType.market
        ? PersonalOrderStatus.inQueue
        : PersonalOrderStatus.resting;
    Navigator.of(context).pop(
      PersonalOrder(
        id: 'new',
        side: _side,
        orderType: _type,
        quantity: qty,
        limitPrice: limit,
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: const ValueKey('new-order-dialog'),
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New order', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Market reference ${widget.marketPrice.toStringAsFixed(2)}',
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Side', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    key: const ValueKey('new-order-side-buy'),
                    label: 'Buy',
                    variant: _side == PersonalOrderSide.buy
                        ? NeonButtonVariant.primary
                        : NeonButtonVariant.outline,
                    onPressed: () =>
                        setState(() => _side = PersonalOrderSide.buy),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: NeonButton(
                    key: const ValueKey('new-order-side-sell'),
                    label: 'Sell',
                    variant: _side == PersonalOrderSide.sell
                        ? NeonButtonVariant.primary
                        : NeonButtonVariant.outline,
                    onPressed: () =>
                        setState(() => _side = PersonalOrderSide.sell),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Type', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    key: const ValueKey('new-order-type-limit'),
                    label: 'Limit',
                    variant: _type == PersonalOrderType.limit
                        ? NeonButtonVariant.primary
                        : NeonButtonVariant.outline,
                    onPressed: () =>
                        setState(() => _type = PersonalOrderType.limit),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: NeonButton(
                    key: const ValueKey('new-order-type-market'),
                    label: 'Market',
                    variant: _type == PersonalOrderType.market
                        ? NeonButtonVariant.primary
                        : NeonButtonVariant.outline,
                    onPressed: () =>
                        setState(() => _type = PersonalOrderType.market),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const ValueKey('new-order-qty'),
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            if (_type == PersonalOrderType.limit) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('new-order-limit'),
                controller: _limitCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTypography.bodyMedium,
                decoration: const InputDecoration(
                  labelText: 'Limit price',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    key: const ValueKey('new-order-dismiss'),
                    label: 'Close',
                    variant: NeonButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: NeonButton(
                    key: const ValueKey('new-order-submit'),
                    label: 'Place order',
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
