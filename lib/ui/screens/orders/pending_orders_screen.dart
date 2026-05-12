import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/trading/personal_order.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/new_order_modal.dart';
import '../../widgets/pending_order_card.dart';
import '../trading/trading_mock_data.dart';
import 'pending_orders_mock_data.dart';
import 'pending_orders_view_data.dart';

/// Callback after the user confirms **Place order** on the shell Orders tab.
/// When non-null, orders are submitted via [CommandRepository.submitCreateOrder]
/// and the screen does **not** prepend a local-only row.
typedef PendingOrdersOnSubmitNewOrder = Future<void> Function({
  required String gameId,
  required GameScopedNewOrder created,
});

/// Global pending orders (**C9**). Shell provides header + bottom nav.
///
/// Rows render **newest [PersonalOrder.createdAt] first** (`null` times sort
/// last). The order of [items] is ignored for display. Default mocks use historic
/// [createdAt] so live inserts naturally sort above them.
///
/// [tradingGamesForNewOrder] lists joined games in `trading_started` — required
/// for **Create new order** when using explicit [items]. When both [items] and
/// [tradingGamesForNewOrder] are omitted, mock defaults derive eligibility from
/// the sample pending list (UI demos only).
class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({
    super.key,
    this.items,
    this.tradingGamesForNewOrder,
    this.onCancelOrder,
    this.onSubmitNewOrder,
  });

  /// When `null`, uses [kMockPendingOrders].
  final List<PendingOrderListItem>? items;

  /// Joined games where `game_state == trading_started`. When non-null, defines
  /// who may tap **Create new order** (independent of pending rows).
  final List<TradingOrderTargetGame>? tradingGamesForNewOrder;

  /// Stream C stub after user confirms cancellation in [PendingOrderCard].
  final ValueChanged<String>? onCancelOrder;

  /// When set (shell route), new orders are sent to the backend; otherwise the
  /// screen inserts a local mock row (tests / standalone widget demos).
  final PendingOrdersOnSubmitNewOrder? onSubmitNewOrder;

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  late List<PendingOrderListItem> _source;
  PendingOrdersFilterState _filter = PendingOrdersFilterState.initial;
  var _crossGameOrderSeq = 0;

  @override
  void initState() {
    super.initState();
    _source = widget.items != null
        ? List<PendingOrderListItem>.from(widget.items!)
        : kMockPendingOrders();
  }

  @override
  void didUpdateWidget(covariant PendingOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items ||
        widget.tradingGamesForNewOrder != oldWidget.tradingGamesForNewOrder) {
      _source = widget.items != null
          ? List<PendingOrderListItem>.from(widget.items!)
          : kMockPendingOrders();
    }
  }

  /// Games the user may place orders in — from [tradingGamesForNewOrder], or
  /// (mock-only) derived from [_source] when [items] is null.
  List<TradingOrderTargetGame> get _eligibleGames {
    if (widget.tradingGamesForNewOrder != null) {
      return widget.tradingGamesForNewOrder!;
    }
    if (widget.items == null) {
      return tradingOrderTargetsFromPendingRows(_source);
    }
    return const [];
  }

  List<String> get _distinctSortedGameTitles {
    final s = _source.map((e) => e.gameTitle).toSet().toList()
      ..sort();
    return s;
  }

  /// Filtered rows, sorted **`createdAt` descending** (latest first).
  List<PendingOrderListItem> get _visible {
    final filtered = applyPendingOrdersFilters(_source, _filter);
    return pendingOrderListItemsSortedNewestFirst(filtered);
  }

  Future<void> _openFilterSheet() async {
    final chosen = await showModalBottomSheet<PendingOrdersFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _PendingOrdersFilterSheet(
        initial: _filter,
        gameTitles: _distinctSortedGameTitles,
      ),
    );
    if (!mounted || chosen == null) return;
    setState(() => _filter = chosen);
  }

  String _allocateCrossGameOrderId() {
    _crossGameOrderSeq += 1;
    return 'pending-xg-$_crossGameOrderSeq';
  }

  double _referencePriceForGameTitle(String title) {
    for (final e in _source) {
      if (e.gameTitle == title) {
        return e.order.limitPrice ?? 150.0;
      }
    }
    return 150.0;
  }

  String _descriptionForGameTitle(String title) {
    for (final g in _eligibleGames) {
      if (g.gameTitle == title) return g.gameDescription;
    }
    for (final e in _source) {
      if (e.gameTitle == title) {
        return e.gameDescription;
      }
    }
    return '';
  }

  String _gameIdForGameTitle(String title) {
    for (final g in _eligibleGames) {
      if (g.gameTitle == title) return g.gameId;
    }
    for (final e in _source) {
      if (e.gameTitle == title) return e.gameId;
    }
    return 'g-cross';
  }

  String? _gameIdForEligibleTitle(String title) {
    for (final g in _eligibleGames) {
      if (g.gameTitle == title) return g.gameId;
    }
    return null;
  }

  Future<void> _openNewOrder() async {
    final titles = _eligibleGames.map((e) => e.gameTitle).toSet().toList()
      ..sort();
    if (titles.isEmpty) return;
    final useLivePrices =
        widget.onSubmitNewOrder != null && _eligibleGames.isNotEmpty;
    final created = await NewOrderModal.showChoosingGame(
      context,
      gameTitles: titles,
      gameIdForTitle: useLivePrices ? _gameIdForEligibleTitle : null,
      // Live games: last traded / limit seed come from tradingViewDataProvider only.
      // Do not reuse pending rows' limit prices (they are order prices, not market).
      marketPriceForGameTitle:
          useLivePrices ? null : _referencePriceForGameTitle,
      bidAskMidpointForGameTitle:
          useLivePrices ? null : mockBidAskMidpointForGameTitle,
    );
    if (!mounted || created == null) return;

    if (widget.onSubmitNewOrder != null) {
      final gid = _gameIdForEligibleTitle(created.gameTitle);
      if (gid == null || gid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not submit order'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      try {
        await widget.onSubmitNewOrder!(
          gameId: gid,
          created: created,
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not submit order'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    final id = _allocateCrossGameOrderId();
    setState(() {
      _source = [
        PendingOrderListItem(
          gameId: _gameIdForGameTitle(created.gameTitle),
          gameTitle: created.gameTitle,
          gameDescription: _descriptionForGameTitle(created.gameTitle),
          order: created.order.copyWith(id: id),
        ),
        ..._source,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      key: const ValueKey('pending-orders-scaffold'),
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      key: const ValueKey('pending-orders-title'),
                      'Pending Orders',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('pending-orders-filter-btn'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textTertiary,
                      ),
                      onPressed: () => _openFilterSheet(),
                      child: Text(
                        'Filter',
                        style: AppTypography.monoSmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (visible.isEmpty)
                  _EmptyBanner(
                    key: const ValueKey('pending-orders-empty'),
                    anySourceItems: _source.isNotEmpty,
                  )
                else
                  ...visible.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: PendingOrderCard(
                        gameTitle: e.gameTitle,
                        gameDescription: e.gameDescription,
                        order: e.order,
                        onCancelRequested:
                            widget.onCancelOrder != null
                                ? (id) => widget.onCancelOrder!(id)
                                : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: AppColors.background,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: NeonButton(
                  key: const ValueKey('pending-orders-create-new-order'),
                  label: 'Create new order',
                  onPressed:
                      _eligibleGames.isEmpty ? null : _openNewOrder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({
    super.key,
    required this.anySourceItems,
  });

  final bool anySourceItems;

  @override
  Widget build(BuildContext context) {
    final msg = anySourceItems
        ? 'No orders for this filter'
        : 'No pending orders';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineSubtle),
      ),
      child: Text(
        msg,
        key: ValueKey('pending-orders-empty-msg-${anySourceItems ? 'filter' : 'zero'}'),
        textAlign: TextAlign.center,
        style: AppTypography.monoSmall.copyWith(
          fontSize: 13,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _PendingOrdersFilterSheet extends StatefulWidget {
  const _PendingOrdersFilterSheet({
    required this.initial,
    required this.gameTitles,
  });

  final PendingOrdersFilterState initial;
  final List<String> gameTitles;

  @override
  State<_PendingOrdersFilterSheet> createState() =>
      _PendingOrdersFilterSheetState();
}

class _PendingOrdersFilterSheetState extends State<_PendingOrdersFilterSheet> {
  late Set<PersonalOrderSide> _directions;
  late Set<String> _gameSelection;

  @override
  void initState() {
    super.initState();
    _directions = Set<PersonalOrderSide>.from(widget.initial.directions);
    _gameSelection = Set<String>.from(widget.initial.selectedGameTitles);
  }

  void _apply() {
    Navigator.of(context).pop(
      PendingOrdersFilterState(
        directions: Set<PersonalOrderSide>.from(_directions),
        selectedGameTitles: Set<String>.from(_gameSelection),
      ),
    );
  }

  void _reset() {
    Navigator.of(context).pop(PendingOrdersFilterState.initial);
  }

  static String _sanitizeKey(String title) =>
      title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'FILTERS',
                textAlign: TextAlign.center,
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'DIRECTION',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                key: const ValueKey('pending-orders-filter-dir-buy'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Buy',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                value: _directions.contains(PersonalOrderSide.buy),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _directions.add(PersonalOrderSide.buy);
                    } else {
                      _directions.remove(PersonalOrderSide.buy);
                    }
                  });
                },
                activeColor: AppColors.primary,
                checkColor: AppColors.background,
                side: BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('pending-orders-filter-dir-sell'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Sell',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                value: _directions.contains(PersonalOrderSide.sell),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _directions.add(PersonalOrderSide.sell);
                    } else {
                      _directions.remove(PersonalOrderSide.sell);
                    }
                  });
                },
                activeColor: AppColors.secondary,
                checkColor: AppColors.background,
                side: BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'GAMES',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (widget.gameTitles.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'No games in this list',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 12,
                    ),
                  ),
                )
              else ...[
                  CheckboxListTile(
                    key: const ValueKey(
                      'pending-orders-filter-games-select-all',
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      '(Select All)',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    value: widget.gameTitles.isNotEmpty &&
                        _gameSelection.length ==
                            widget.gameTitles.length &&
                        widget.gameTitles.every(_gameSelection.contains),
                    tristate: false,
                    onChanged: widget.gameTitles.isEmpty
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _gameSelection =
                                    Set<String>.from(widget.gameTitles);
                              } else {
                                _gameSelection.clear();
                              }
                            });
                          },
                    side: BorderSide(
                      color: AppColors.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  ...widget.gameTitles.map((t) {
                    return CheckboxListTile(
                      key: ValueKey(
                        'pending-orders-filter-game-${_sanitizeKey(t)}',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        t,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      value: _gameSelection.contains(t),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _gameSelection.add(t);
                          } else {
                            _gameSelection.remove(t);
                          }
                        });
                      },
                      side: BorderSide(
                        color: AppColors.outline.withValues(alpha: 0.5),
                      ),
                    );
                  }),
                ],
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      key: const ValueKey('pending-orders-filter-reset'),
                      label: 'Reset',
                      variant: NeonButtonVariant.outline,
                      onPressed: _reset,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: NeonButton(
                      key: const ValueKey('pending-orders-filter-apply'),
                      label: 'Apply',
                      variant: NeonButtonVariant.primary,
                      onPressed: _apply,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
