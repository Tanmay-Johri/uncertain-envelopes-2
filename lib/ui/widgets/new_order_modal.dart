import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/limit_price_input.dart';
import '../../core/trading/order_quantity_input.dart';
import '../../core/trading/personal_order.dart';
import 'neon_button.dart';

/// Same palette as status chip `order_closed` / `cancelled` (transparent fill + border).
final PersonalOrderStatusChipStyle _kNewOrderChipGreen =
    personalOrderStatusChipStyle(PersonalOrderStatus.filled);
final PersonalOrderStatusChipStyle _kNewOrderChipRed =
    personalOrderStatusChipStyle(PersonalOrderStatus.cancelled);

/// Unselected Side / Type cells: no green or red — only neutral chrome.
const PersonalOrderStatusChipStyle _kNeutralOrderChipStyle =
    PersonalOrderStatusChipStyle(
  foreground: AppColors.textTertiary,
  border: Color(0xFF3F3F3F),
  background: AppColors.surfaceContainerHigh,
);

/// C6 mock: create order dialog. Returns a [PersonalOrder] with a placeholder
/// [PersonalOrder.id] (`new`) — the screen assigns a real id.
class NewOrderModal extends StatefulWidget {
  const NewOrderModal({
    super.key,
    required this.marketPrice,
    this.marketPriceListenable,
    this.bidAskMidpointListenable,
  });

  final double marketPrice;

  /// When set (e.g. live game tick), the **Last Traded Price** line tracks
  /// [ValueListenable.value] while this dialog is open.
  final ValueListenable<double>? marketPriceListenable;

  /// Live bid–ask midpoint (`null` shows `-`); omitted in tests that do not
  /// model an order book.
  final ValueListenable<double?>? bidAskMidpointListenable;

  static Future<PersonalOrder?> show(
    BuildContext context, {
    required double marketPrice,
    ValueListenable<double>? marketPriceListenable,
    ValueListenable<double?>? bidAskMidpointListenable,
  }) {
    return showDialog<PersonalOrder>(
      context: context,
      barrierDismissible: true,
      builder: (_) => NewOrderModal(
        marketPrice: marketPrice,
        marketPriceListenable: marketPriceListenable,
        bidAskMidpointListenable: bidAskMidpointListenable,
      ),
    );
  }

  @override
  State<NewOrderModal> createState() => _NewOrderModalState();
}

class _NewOrderModalState extends State<NewOrderModal> {
  late PersonalOrderSide _side;
  late PersonalOrderType _type;
  final _qtyCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _qtyFocus = FocusNode();
  final _limitFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _side = PersonalOrderSide.buy;
    _type = PersonalOrderType.limit;
    _qtyCtrl.value = const TextEditingValue(
      text: '1',
      selection: TextSelection.collapsed(offset: 1),
    );
    final initialLimit = normalizeLimitPriceFieldText(
      widget.marketPrice.toString(),
      widget.marketPrice,
    );
    _limitCtrl.value = TextEditingValue(
      text: initialLimit,
      selection: TextSelection.collapsed(offset: initialLimit.length),
    );
    _limitCtrl.addListener(_onLimitFieldChanged);
  }

  void _onLimitFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _limitCtrl.removeListener(_onLimitFieldChanged);
    _qtyFocus.dispose();
    _limitFocus.dispose();
    _qtyCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  void _commitQtyText(String next) {
    setState(() {
      _qtyCtrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });
  }

  void _normalizeQtyField() {
    _commitQtyText(normalizeOrderQtyFieldText(_qtyCtrl.text));
  }

  void _onQtyTapOutside(PointerDownEvent event) {
    _qtyFocus.unfocus();
    _normalizeQtyField();
  }

  void _onQtyEditingComplete() {
    _normalizeQtyField();
    _qtyFocus.unfocus();
  }

  void _bumpQty(int delta) {
    setState(() {
      final q = int.parse(normalizeOrderQtyFieldText(_qtyCtrl.text));
      final n = q + delta;
      final t = n < 1 ? '1' : '$n';
      _qtyCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    });
  }

  double _effectiveMarketPrice() {
    return widget.marketPriceListenable?.value ?? widget.marketPrice;
  }

  void _commitLimitText(String next) {
    setState(() {
      _limitCtrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });
  }

  void _normalizeLimitField() {
    _commitLimitText(
      normalizeLimitPriceFieldText(
        _limitCtrl.text,
        _effectiveMarketPrice(),
      ),
    );
  }

  void _onLimitTapOutside(PointerDownEvent event) {
    _limitFocus.unfocus();
    _normalizeLimitField();
  }

  void _onLimitEditingComplete() {
    _normalizeLimitField();
    _limitFocus.unfocus();
  }

  void _bumpLimit(double delta) {
    setState(() {
      final cur =
          double.tryParse(_limitCtrl.text.trim()) ?? _effectiveMarketPrice();
      var n = cur + delta;
      if (n < kLimitPriceMinPositive) {
        n = kLimitPriceMinPositive;
      }
      final t = formatLimitPriceForField(
        n,
        rawHint: _limitCtrl.text,
      );
      _limitCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    });
  }

  /// Human-readable limit [X] for the stance line; falls back when the field
  /// does not yet parse as a submit-ready positive limit.
  String _limitPriceLabelForStance() {
    final p = parseLimitPriceForSubmit(_limitCtrl.text);
    if (p != null) {
      return formatLimitPriceForField(p, rawHint: _limitCtrl.text);
    }
    return '…';
  }

  /// Limit fragment for stance copy: `$` + digits, or ellipsis only.
  String _stanceLimitPriceDisplay() {
    final x = _limitPriceLabelForStance();
    if (x == '…') return x;
    return '\$$x';
  }

  String _stanceQuotedSentence() {
    if (_type == PersonalOrderType.market) {
      if (_side == PersonalOrderSide.buy) {
        return '"You are betting that the envelope value will increase"';
      }
      return '"You are betting that the envelope value will decrease"';
    }
    final x = _stanceLimitPriceDisplay();
    if (_side == PersonalOrderSide.buy) {
      return '"You are betting that the envelope value will be more than $x"';
    }
    return '"You are betting that the envelope value will be less than $x"';
  }

  void _submit() {
    final qty = parseOrderQtyForSubmit(_qtyCtrl.text);
    if (qty == null) {
      return;
    }
    double? limit;
    if (_type == PersonalOrderType.limit) {
      limit = parseLimitPriceForSubmit(_limitCtrl.text);
      if (limit == null) {
        return;
      }
    }
    // Limit and market orders both enter `in_queue` first (worker → resting, etc.).
    Navigator.of(context).pop(
      PersonalOrder(
        id: 'new',
        side: _side,
        orderType: _type,
        quantityInitial: qty,
        quantityCurrent: qty,
        limitPrice: limit,
        status: PersonalOrderStatus.inQueue,
        createdAt: DateTime.now().toUtc(),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text('New order', style: AppTypography.screenTitle),
                ),
                IconButton(
                  key: const ValueKey('new-order-close'),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    minimumSize: const Size(40, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _LastTradedPriceLine(
              marketPrice: widget.marketPrice,
              marketPriceListenable: widget.marketPriceListenable,
            ),
            if (widget.bidAskMidpointListenable != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _BidAskMidpointLine(
                listenable: widget.bidAskMidpointListenable!,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              _stanceQuotedSentence(),
              key: const ValueKey('new-order-stance'),
              style: AppTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Side', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _ChipToggleButton(
                    key: const ValueKey('new-order-side-buy'),
                    label: 'Buy',
                    selected: _side == PersonalOrderSide.buy,
                    palette: _kNewOrderChipGreen,
                    onPressed: () =>
                        setState(() => _side = PersonalOrderSide.buy),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChipToggleButton(
                    key: const ValueKey('new-order-side-sell'),
                    label: 'Sell',
                    selected: _side == PersonalOrderSide.sell,
                    palette: _kNewOrderChipRed,
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
                  child: _ChipToggleButton(
                    key: const ValueKey('new-order-type-limit'),
                    label: 'Limit',
                    selected: _type == PersonalOrderType.limit,
                    palette: _side == PersonalOrderSide.buy
                        ? _kNewOrderChipGreen
                        : _kNewOrderChipRed,
                    onPressed: () =>
                        setState(() => _type = PersonalOrderType.limit),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ChipToggleButton(
                    key: const ValueKey('new-order-type-market'),
                    label: 'Market',
                    selected: _type == PersonalOrderType.market,
                    palette: _side == PersonalOrderSide.buy
                        ? _kNewOrderChipGreen
                        : _kNewOrderChipRed,
                    onPressed: () =>
                        setState(() => _type = PersonalOrderType.market),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Quantity', style: AppTypography.label),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  key: const ValueKey('new-order-qty-minus'),
                  tooltip: 'Decrease quantity',
                  onPressed: () => _bumpQty(-1),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextField(
                    key: const ValueKey('new-order-qty'),
                    controller: _qtyCtrl,
                    focusNode: _qtyFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [
                      OrderQtyDecimalTextInputFormatter(),
                    ],
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Quantity',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    onEditingComplete: _onQtyEditingComplete,
                    onTapOutside: _onQtyTapOutside,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  key: const ValueKey('new-order-qty-plus'),
                  tooltip: 'Increase quantity',
                  onPressed: () => _bumpQty(1),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ],
            ),
            if (_type == PersonalOrderType.limit) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Limit price', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    key: const ValueKey('new-order-limit-minus'),
                    tooltip: 'Decrease limit by ${kLimitPriceStep.toStringAsFixed(2)}',
                    onPressed: () => _bumpLimit(-kLimitPriceStep),
                    icon: const Icon(Icons.remove),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('new-order-limit'),
                      controller: _limitCtrl,
                      focusNode: _limitFocus,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: const [
                        OrderQtyDecimalTextInputFormatter(),
                      ],
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Limit price',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onEditingComplete: _onLimitEditingComplete,
                      onTapOutside: _onLimitTapOutside,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton(
                    key: const ValueKey('new-order-limit-plus'),
                    tooltip: 'Increase limit by ${kLimitPriceStep.toStringAsFixed(2)}',
                    onPressed: () => _bumpLimit(kLimitPriceStep),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            NeonButton(
              key: const ValueKey('new-order-submit'),
              label: 'Place order',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _LastTradedPriceLine extends StatelessWidget {
  const _LastTradedPriceLine({
    required this.marketPrice,
    required this.marketPriceListenable,
  });

  final double marketPrice;
  final ValueListenable<double>? marketPriceListenable;

  @override
  Widget build(BuildContext context) {
    final listenable = marketPriceListenable;
    if (listenable == null) {
      return Text(
        'Last Traded Price \$${marketPrice.toStringAsFixed(2)}',
        style: AppTypography.monoSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final m = listenable.value;
        return Text(
          'Last Traded Price \$${m.toStringAsFixed(2)}',
          style: AppTypography.monoSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        );
      },
    );
  }
}

class _BidAskMidpointLine extends StatelessWidget {
  const _BidAskMidpointLine({required this.listenable});

  final ValueListenable<double?> listenable;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final v = listenable.value;
        final valueText = v == null ? '-' : '\$${v.toStringAsFixed(2)}';
        return Text(
          'Bid Ask Midpoint $valueText',
          key: const ValueKey('new-order-bid-ask-mid'),
          style: AppTypography.monoSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        );
      },
    );
  }
}

/// Segmented control cell matching [personalOrderStatusChipStyle] (outline + tint).
class _ChipToggleButton extends StatelessWidget {
  const _ChipToggleButton({
    super.key,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  /// Strong green/red chip when [selected]; [_kNeutralOrderChipStyle] when not.
  final PersonalOrderStatusChipStyle palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = selected ? palette : _kNeutralOrderChipStyle;
    final textStyle = AppTypography.buttonSecondary.copyWith(
      color: s.foreground,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: s.foreground.withValues(alpha: 0.12),
        highlightColor: s.foreground.withValues(alpha: 0.06),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: s.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: s.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  label.toUpperCase(),
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
