import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/trading/limit_price_input.dart';
import '../../core/trading/order_quantity_input.dart';
import '../../core/trading/personal_order.dart';
import '../../providers/view_data/trading_view_data_provider.dart';
import '../screens/trading/trading_view_data.dart';
import 'neon_button.dart';

/// Wraps dialog content so [ConsumerWidget]s resolve [Ref] correctly: reuse the
/// app [ProviderContainer] when present; otherwise create a scope for widget
/// tests that pump [MaterialApp] without Riverpod.
Widget _newOrderDialogShell(BuildContext context, Widget child) {
  try {
    final container = ProviderScope.containerOf(context);
    return UncontrolledProviderScope(
      container: container,
      child: child,
    );
  } catch (_) {
    return ProviderScope(child: child);
  }
}

/// Populated only from [NewOrderModal.showChoosingGame].
@immutable
class GameScopedNewOrder {
  const GameScopedNewOrder({
    required this.gameTitle,
    required this.order,
  });

  final String gameTitle;
  final PersonalOrder order;
}

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
class NewOrderModal extends ConsumerStatefulWidget {
  const NewOrderModal({
    super.key,
    required this.marketPrice,
    this.marketPriceListenable,
    this.bidAskMidpointListenable,
    this.gameTitles,
    this.marketPriceForGameTitle,
    this.bidAskMidpointForGameTitle,
    this.gameIdForTitle,
  });

  /// Last traded reference for limit defaults and labeling (`null` → hyphen).
  final double? marketPrice;

  /// When set (e.g. live game tick), the **Last Traded Price** line tracks
  /// [ValueListenable.value] while this dialog is open.
  final ValueListenable<double?>? marketPriceListenable;

  /// Live bid–ask midpoint (`null` shows `-`); omitted in tests that do not
  /// model an order book.
  final ValueListenable<double?>? bidAskMidpointListenable;

  /// When non-null and non-empty, shows a single-select game dropdown before
  /// price copy. Submit pops [GameScopedNewOrder] ([showChoosingGame] only).
  final List<String>? gameTitles;

  /// Per-game hint for Last Traded / limit defaults when [gameTitles] is used.
  final double? Function(String gameTitle)? marketPriceForGameTitle;

  /// When [gameTitles] is used: bid–ask midpoint per title (`null` → hyphen).
  /// Prefer this over [bidAskMidpointListenable] when the picker changes game.
  /// Ignored when [gameIdForTitle] is set (live book via [tradingViewDataProvider]).
  final double? Function(String gameTitle)? bidAskMidpointForGameTitle;

  /// When set with [gameTitles], resolves each title to a game id so Last Traded
  /// Price and bid–ask midpoint load from [tradingViewDataProvider].
  final String? Function(String gameTitle)? gameIdForTitle;

  /// Trading route: unchanged return type ([gameTitles] omitted).
  static Future<PersonalOrder?> show(
    BuildContext context, {
    required double? marketPrice,
    ValueListenable<double?>? marketPriceListenable,
    ValueListenable<double?>? bidAskMidpointListenable,
  }) {
    return showDialog<PersonalOrder>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _newOrderDialogShell(
        context,
        NewOrderModal(
          marketPrice: marketPrice,
          marketPriceListenable: marketPriceListenable,
          bidAskMidpointListenable: bidAskMidpointListenable,
        ),
      ),
    );
  }

  /// Pending-orders shell: same dialog body plus **exactly one** game pick.
  ///
  /// When [gameIdForTitle] is set, last traded / default limit price come from
  /// [tradingViewDataProvider]. Otherwise use [marketPriceForGameTitle], then
  /// [fallbackMarketPrice] if provided (no implicit default — avoids wrong limits).
  static Future<GameScopedNewOrder?> showChoosingGame(
    BuildContext context, {
    required List<String> gameTitles,
    double? fallbackMarketPrice,
    double? Function(String gameTitle)? marketPriceForGameTitle,
    double? Function(String gameTitle)? bidAskMidpointForGameTitle,
    String? Function(String gameTitle)? gameIdForTitle,
    ValueListenable<double?>? marketPriceListenable,
    ValueListenable<double?>? bidAskMidpointListenable,
  }) {
    final titles = List<String>.of(gameTitles)..sort();
    if (titles.isEmpty) {
      return Future.value(null);
    }
    final resolvedMarketForTitle = marketPriceForGameTitle ??
        (fallbackMarketPrice != null ? (_) => fallbackMarketPrice : null);
    return showDialog<GameScopedNewOrder>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _newOrderDialogShell(
        context,
        NewOrderModal(
          marketPrice: fallbackMarketPrice,
          marketPriceListenable: marketPriceListenable,
          bidAskMidpointListenable: bidAskMidpointListenable,
          gameTitles: titles,
          marketPriceForGameTitle: resolvedMarketForTitle,
          bidAskMidpointForGameTitle: bidAskMidpointForGameTitle,
          gameIdForTitle: gameIdForTitle,
        ),
      ),
    );
  }

  @override
  ConsumerState<NewOrderModal> createState() => _NewOrderModalState();
}

class _NewOrderModalState extends ConsumerState<NewOrderModal> {
  late PersonalOrderSide _side;
  late PersonalOrderType _type;
  late String _selectedGame;
  final _qtyCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _qtyFocus = FocusNode();
  final _limitFocus = FocusNode();

  bool get _gamesMode =>
      widget.gameTitles != null && widget.gameTitles!.isNotEmpty;

  GameTradingViewData? _liveTradingSnapshot({bool listen = true}) {
    if (!_gamesMode || widget.gameIdForTitle == null) return null;
    final gid = widget.gameIdForTitle!(_selectedGame);
    if (gid == null || gid.isEmpty) return null;
    final async = listen
        ? ref.watch(tradingViewDataProvider(gid))
        : ref.read(tradingViewDataProvider(gid));
    return async.asData?.value;
  }

  double? _liveBidAskMid() {
    final d = _liveTradingSnapshot();
    if (d == null) return null;
    return computeBidAskMidpoint(d.orderBookBids, d.orderBookAsks);
  }

  double? _baseMarketForSelectedGame({bool listen = true}) {
    final live = _liveTradingSnapshot(listen: listen);
    if (live?.marketPrice != null) return live!.marketPrice;

    if (_gamesMode) {
      return widget.marketPriceForGameTitle?.call(_selectedGame) ??
          widget.marketPrice;
    }
    return widget.marketPrice;
  }

  double? _seedMarketSnapshot() =>
      widget.marketPriceListenable?.value ??
      _baseMarketForSelectedGame(listen: false);

  @override
  void initState() {
    super.initState();
    _side = PersonalOrderSide.buy;
    _type = PersonalOrderType.limit;
    _selectedGame = _gamesMode ? widget.gameTitles!.first : '';
    _qtyCtrl.value = const TextEditingValue(
      text: '1',
      selection: TextSelection.collapsed(offset: 1),
    );
    final seedMarket = _seedMarketSnapshot();
    final initialLimit = seedMarket == null
        ? ''
        : normalizeLimitPriceFieldText(
            seedMarket.toString(),
            seedMarket,
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

  double? _effectiveMarketPrice() {
    final live = _liveTradingSnapshot();
    if (live?.marketPrice != null) return live!.marketPrice;
    return widget.marketPriceListenable?.value ?? _baseMarketForSelectedGame();
  }

  void _onGameChanged(String? next) {
    if (next == null) return;
    setState(() {
      _selectedGame = next;
      final mp =
          widget.marketPriceListenable?.value ?? _baseMarketForSelectedGame();
      if (mp == null) {
        _limitCtrl.value = const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      } else {
        final normalized = normalizeLimitPriceFieldText(
          mp.toString(),
          mp,
        );
        _limitCtrl.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
        );
      }
    });
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
      final cur = double.tryParse(_limitCtrl.text.trim()) ??
          _effectiveMarketPrice() ??
          kLimitPriceMinPositive;
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
    final order = PersonalOrder(
      id: 'new',
      side: _side,
      orderType: _type,
      quantityInitial: qty,
      quantityCurrent: qty,
      limitPrice: limit,
      status: PersonalOrderStatus.inQueue,
      createdAt: DateTime.now().toUtc(),
    );
    final nav = Navigator.of(context);
    if (!_gamesMode) {
      nav.pop(order);
      return;
    }
    nav.pop(
      GameScopedNewOrder(gameTitle: _selectedGame, order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gamesMode && widget.gameIdForTitle != null) {
      final gid = widget.gameIdForTitle!(_selectedGame);
      if (gid != null && gid.isNotEmpty) {
        ref.listen(tradingViewDataProvider(gid), (previous, next) {
          next.whenData((data) {
            final mp = data.marketPrice;
            if (!mounted || mp == null) return;
            if (_limitCtrl.text.trim().isNotEmpty) return;
            final normalized = normalizeLimitPriceFieldText(
              mp.toString(),
              mp,
            );
            _limitCtrl.value = TextEditingValue(
              text: normalized,
              selection: TextSelection.collapsed(offset: normalized.length),
            );
            setState(() {});
          });
        });
      }
    }
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;
    return Dialog(
      key: const ValueKey('new-order-dialog'),
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
            if (_gamesMode) ...[
              Text('Game', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                key: const ValueKey('new-order-game'),
                initialValue: _selectedGame,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                items: widget.gameTitles!
                    .map(
                      (g) => DropdownMenuItem<String>(
                        value: g,
                        child: Text(
                          g,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _onGameChanged,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _LastTradedPriceLine(
              marketPrice: _effectiveMarketPrice(),
              marketPriceListenable: widget.marketPriceListenable,
            ),
            if (widget.bidAskMidpointListenable != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _BidAskMidpointLine(
                listenable: widget.bidAskMidpointListenable!,
              ),
            ] else if (_gamesMode && widget.gameIdForTitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _bidAskMidpointLabelText(_liveBidAskMid()),
            ] else if (_gamesMode &&
                widget.bidAskMidpointForGameTitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _ResolvedBidAskMidpointLine(
                gameTitle: _selectedGame,
                resolve: widget.bidAskMidpointForGameTitle!,
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
    ),
    );
  }
}

class _LastTradedPriceLine extends StatelessWidget {
  const _LastTradedPriceLine({
    required this.marketPrice,
    required this.marketPriceListenable,
  });

  final double? marketPrice;
  final ValueListenable<double?>? marketPriceListenable;

  static String _valueLabel(double? m) => m == null ? '-' : '\$${m.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final listenable = marketPriceListenable;
    if (listenable == null) {
      return Text(
        'Last Traded Price ${_valueLabel(marketPrice)}',
        style: AppTypography.monoSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      );
    }
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        return Text(
          'Last Traded Price ${_valueLabel(listenable.value)}',
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
        return _bidAskMidpointLabelText(listenable.value);
      },
    );
  }
}

class _ResolvedBidAskMidpointLine extends StatelessWidget {
  const _ResolvedBidAskMidpointLine({
    required this.gameTitle,
    required this.resolve,
  });

  final String gameTitle;
  final double? Function(String gameTitle) resolve;

  @override
  Widget build(BuildContext context) {
    return _bidAskMidpointLabelText(resolve(gameTitle));
  }
}

Widget _bidAskMidpointLabelText(double? v) {
  final valueText = v == null ? '-' : '\$${v.toStringAsFixed(2)}';
  return Text(
    'Bid Ask Midpoint $valueText',
    key: const ValueKey('new-order-bid-ask-mid'),
    style: AppTypography.monoSmall.copyWith(
      color: AppColors.textTertiary,
    ),
  );
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
