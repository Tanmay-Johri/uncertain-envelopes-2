import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/order_quantity_input.dart';
import '../../data/models/order.dart';
import '../../providers/trading_provider.dart';
import '../../providers/view_data/pending_orders_view_data_provider.dart';
import '../screens/orders/pending_orders_view_data.dart';

/// Choose how many **pending** (`quantity_current`) units to cancel for a
/// resting `order_resting` row. Live-updates the max bound via
/// [pendingListenable].
///
/// When [liveFromPendingView] is true, subscribes to [pendingOrdersViewDataProvider]
/// so the dialog tracks cross-game pending rows while open (same refresh path as
/// the Orders tab list).
///
/// When [liveGameId] + [liveOrderId] are set (non-empty game id), subscribes to
/// [ordersProvider] so the dialog tracks that game's order list while open
/// (same path as the trading screen).
class PartialCancelOrderModal extends StatefulWidget {
  const PartialCancelOrderModal({
    super.key,
    required this.initialPending,
    required this.pendingListenable,
    this.liveGameId,
    this.liveOrderId,
    this.liveFromPendingView = false,
  });

  final int initialPending;

  /// Drives the pending sentence, stepper max, and clamping logic.
  final ValueNotifier<int?> pendingListenable;

  /// When set with [liveOrderId], listens to [ordersProvider] for live qty.
  final String? liveGameId;

  /// Order id to match against backend rows.
  final String? liveOrderId;

  /// When true, listens to [pendingOrdersViewDataProvider] instead of orders.
  final bool liveFromPendingView;

  static Future<int?> show(
    BuildContext context, {
    required int initialPending,
    required ValueNotifier<int?> pendingListenable,
    String? liveGameId,
    String? liveOrderId,
    bool liveFromPendingView = false,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PartialCancelOrderModal(
        initialPending: initialPending,
        pendingListenable: pendingListenable,
        liveGameId: liveGameId,
        liveOrderId: liveOrderId,
        liveFromPendingView: liveFromPendingView,
      ),
    );
  }

  @override
  State<PartialCancelOrderModal> createState() =>
      _PartialCancelOrderModalState();
}

class _PartialCancelOrderModalState extends State<PartialCancelOrderModal> {
  late final TextEditingController _qtyCtrl;
  late final FocusNode _qtyFocus;

  ProviderSubscription<AsyncValue<List<Order>>>? _ordersLiveSub;
  ProviderSubscription<AsyncValue<PendingOrdersScreenData>>? _pendingViewLiveSub;

  int get _latestPending =>
      widget.pendingListenable.value ?? widget.initialPending;

  @override
  void initState() {
    super.initState();
    final start = widget.initialPending.clamp(1, 1 << 30);
    _qtyCtrl = TextEditingController(text: '$start');
    _qtyFocus = FocusNode();
    widget.pendingListenable.addListener(_onPendingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAttachLiveRiverpodListeners();
    });
  }

  @override
  void dispose() {
    _detachLiveRiverpodListeners();
    widget.pendingListenable.removeListener(_onPendingChanged);
    _qtyCtrl.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PartialCancelOrderModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingListenable != oldWidget.pendingListenable) {
      oldWidget.pendingListenable.removeListener(_onPendingChanged);
      widget.pendingListenable.addListener(_onPendingChanged);
    }
    if (widget.liveGameId != oldWidget.liveGameId ||
        widget.liveOrderId != oldWidget.liveOrderId ||
        widget.liveFromPendingView != oldWidget.liveFromPendingView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAttachLiveRiverpodListeners();
      });
    }
  }

  void _detachLiveRiverpodListeners() {
    _ordersLiveSub?.close();
    _ordersLiveSub = null;
    _pendingViewLiveSub?.close();
    _pendingViewLiveSub = null;
  }

  void _maybeAttachLiveRiverpodListeners() {
    if (!mounted) return;
    _detachLiveRiverpodListeners();

    ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (_) {
      return;
    }

    if (widget.liveFromPendingView && widget.liveOrderId != null) {
      _pendingViewLiveSub =
          container.listen<AsyncValue<PendingOrdersScreenData>>(
        pendingOrdersViewDataProvider,
        (_, next) {
          next.whenData((data) => _applyQtyFromPendingRows(data.items));
        },
        fireImmediately: true,
      );
      return;
    }

    final gid = widget.liveGameId;
    if (gid != null && gid.isNotEmpty && widget.liveOrderId != null) {
      _ordersLiveSub = container.listen<AsyncValue<List<Order>>>(
        ordersProvider(gid),
        (_, next) {
          next.whenData(_applyQtyFromOrders);
        },
        fireImmediately: true,
      );
    }
  }

  void _applyQtyFromOrders(List<Order> orders) {
    final oid = widget.liveOrderId;
    if (oid == null) return;
    for (final o in orders) {
      if (o.orderId == oid) {
        _setPendingNotifierIfChanged(o.quantityCurrent);
        return;
      }
    }
    _setPendingNotifierIfChanged(0);
  }

  void _applyQtyFromPendingRows(List<PendingOrderListItem> rows) {
    final oid = widget.liveOrderId;
    if (oid == null) return;
    for (final e in rows) {
      if (e.order.id == oid) {
        _setPendingNotifierIfChanged(e.order.quantityCurrent);
        return;
      }
    }
    _setPendingNotifierIfChanged(0);
  }

  void _setPendingNotifierIfChanged(int q) {
    final nn = widget.pendingListenable;
    if (nn.value != q) {
      nn.value = q;
    }
  }

  void _onPendingChanged() {
    final n = widget.pendingListenable.value;
    if (n == null || n <= 0) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
      return;
    }
    final max = n;
    final parsed = parseOrderQtyForSubmit(_qtyCtrl.text) ?? 1;
    final clamped = parsed.clamp(1, max);
    if (clamped != parsed) {
      _applyQty(clamped);
    }
    setState(() {});
  }

  void _applyQty(int q) {
    final max = _latestPending.clamp(1, 1 << 30);
    final v = q.clamp(1, max);
    final t = '$v';
    _qtyCtrl.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  void _bumpQty(int delta) {
    final max = _latestPending;
    if (max < 1) return;
    final cur = parseOrderQtyForSubmit(_qtyCtrl.text) ?? 1;
    _applyQty(cur + delta);
    setState(() {});
  }

  void _commitQtyField() {
    final max = _latestPending;
    if (max < 1) return;
    final parsed = parseOrderQtyForSubmit(_qtyCtrl.text);
    if (parsed == null) {
      _applyQty(1);
    } else {
      _applyQty(parsed);
    }
    setState(() {});
  }

  void _submit() {
    final max = _latestPending;
    if (max < 1) return;
    final q = parseOrderQtyForSubmit(_qtyCtrl.text);
    if (q == null) return;
    final v = q.clamp(1, max);
    Navigator.of(context).pop(v);
  }

  @override
  Widget build(BuildContext context) {
    final max = _latestPending;
    final cur = parseOrderQtyForSubmit(_qtyCtrl.text) ?? 1;
    final parsedOk = parseOrderQtyForSubmit(_qtyCtrl.text) != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Dialog(
      key: const ValueKey('partial-cancel-order-dialog'),
      backgroundColor: AppColors.surfaceContainer,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Cancel order',
                      style: AppTypography.screenTitle,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('partial-cancel-close'),
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
              ValueListenableBuilder<int?>(
                valueListenable: widget.pendingListenable,
                builder: (context, pending, _) {
                  final text = (pending == null || pending <= 0)
                      ? 'No pending units remain for this order.'
                      : 'You have $pending pending unit${pending == 1 ? '' : 's'} of this order left.';
                  return Text(
                    text,
                    key: ValueKey(
                      'partial-cancel-pending-line-${pending ?? 0}',
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  );
                },
              ),
              if (max >= 1) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Units to cancel',
                  style: AppTypography.microLabel.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _StepperSide(
                      key: const ValueKey('partial-cancel-minus'),
                      icon: Icons.remove,
                      onPressed:
                          cur > 1 ? () => _bumpQty(-1) : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('partial-cancel-qty-field'),
                        controller: _qtyCtrl,
                        focusNode: _qtyFocus,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTypography.statValue.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.md,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                        inputFormatters: const [
                          OrderQtyDecimalTextInputFormatter(),
                        ],
                        onEditingComplete: () {
                          _commitQtyField();
                          _qtyFocus.unfocus();
                        },
                        onSubmitted: (_) => _commitQtyField(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _StepperSide(
                      key: const ValueKey('partial-cancel-plus'),
                      icon: Icons.add,
                      onPressed:
                          cur < max ? () => _bumpQty(1) : null,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('partial-cancel-submit'),
                  onPressed: (max >= 1 && parsedOk) ? _submit : null,
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
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text(
                    'Cancel Order',
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
      ),
    );
  }
}

class _StepperSide extends StatelessWidget {
  const _StepperSide({super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
