import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/trading/personal_order.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/pending_order_card.dart';
import 'pending_orders_mock_data.dart';
import 'pending_orders_view_data.dart';

/// Global pending orders (**C9**). Shell provides header + bottom nav.
///
/// Rows render **newest** [PersonalOrder.createdAt] **first** (`null` times
/// sort last). The order of [items] is ignored for display.
class PendingOrdersScreen extends StatefulWidget {
  const PendingOrdersScreen({
    super.key,
    this.items,
    this.now,
    this.onCancelOrder,
  });

  /// When `null`, uses [kMockPendingOrders].
  final List<PendingOrderListItem>? items;

  /// Deterministic clock in tests (`DateTime.now` in routes).
  final DateTime Function()? now;

  /// Stream C stub after user confirms cancellation in [PendingOrderCard].
  final ValueChanged<String>? onCancelOrder;

  @override
  State<PendingOrdersScreen> createState() => _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends State<PendingOrdersScreen> {
  late List<PendingOrderListItem> _source;
  PendingOrdersFilterState _filter = PendingOrdersFilterState.initial;

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
    if (widget.items != oldWidget.items) {
      _source = widget.items != null
          ? List<PendingOrderListItem>.from(widget.items!)
          : kMockPendingOrders();
    }
  }

  DateTime Function() get _effectiveNow =>
      widget.now ?? DateTime.now;

  List<String> get _distinctSortedGameTitles {
    final s = _source.map((e) => e.gameTitle).toSet().toList()
      ..sort();
    return s;
  }

  /// Filtered rows, sorted by **`order.createdAt` descending** (latest first).
  /// Input `items` order is ignored for display ordering.
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

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      key: const ValueKey('pending-orders-scaffold'),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sectionGap + 80,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                key: const ValueKey('pending-orders-title'),
                'Pending Orders',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.9,
                  color: AppColors.textTertiary,
                ),
              ),
              TextButton(
                key: const ValueKey('pending-orders-filter-btn'),
                onPressed: () => _openFilterSheet(),
                child: Text(
                  'Filter',
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.primary,
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
                  now: _effectiveNow,
                  onCancelRequested:
                      widget.onCancelOrder != null
                          ? (id) => widget.onCancelOrder!(id)
                          : null,
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select buy, sell, or both. Pick both sides to see every order.',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    key: const ValueKey('pending-orders-filter-dir-buy'),
                    label: Text(
                      'Buy',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _directions.contains(PersonalOrderSide.buy),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _directions.add(PersonalOrderSide.buy);
                        } else {
                          _directions.remove(PersonalOrderSide.buy);
                        }
                      });
                    },
                    selectedColor:
                        AppColors.primary.withValues(alpha: 0.18),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _directions.contains(PersonalOrderSide.buy)
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  FilterChip(
                    key: const ValueKey('pending-orders-filter-dir-sell'),
                    label: Text(
                      'Sell',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _directions.contains(PersonalOrderSide.sell),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _directions.add(PersonalOrderSide.sell);
                        } else {
                          _directions.remove(PersonalOrderSide.sell);
                        }
                      });
                    },
                    selectedColor:
                        AppColors.secondary.withValues(alpha: 0.15),
                    checkmarkColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: _directions.contains(PersonalOrderSide.sell)
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Multi-select games. Leave all unchecked to include every game.',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  height: 1.35,
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
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: widget.gameTitles
                      .map(
                        (t) => FilterChip(
                          key: ValueKey(
                            'pending-orders-filter-game-${_sanitizeKey(t)}',
                          ),
                          label: Text(
                            t,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          selected: _gameSelection.contains(t),
                          onSelected: (v) {
                            setState(() {
                              if (v) {
                                _gameSelection.add(t);
                              } else {
                                _gameSelection.remove(t);
                              }
                            });
                          },
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          checkmarkColor: AppColors.primary,
                        ),
                      )
                      .toList(),
                ),
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
