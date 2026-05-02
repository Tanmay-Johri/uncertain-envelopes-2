import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/pending_order_card.dart';
import 'pending_orders_mock_data.dart';
import 'pending_orders_view_data.dart';

/// Global pending orders (**C9**). Shell provides header + bottom nav.
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
  PendingOrdersSideFilter _filter = PendingOrdersSideFilter.all;

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

  List<PendingOrderListItem> get _visible {
    final filtered = applyPendingOrdersSideFilter(_source, _filter);
    return pendingOrderListItemsSortedNewestFirst(filtered);
  }

  Future<void> _openSideFilter() async {
    final chosen = await showModalBottomSheet<PendingOrdersSideFilter>(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => _SideFilterSheet(current: _filter),
    );
    if (!mounted || chosen == null || chosen == _filter) return;
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
                onPressed: () => _openSideFilter(),
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

class _SideFilterSheet extends StatelessWidget {
  const _SideFilterSheet({required this.current});

  final PendingOrdersSideFilter current;

  String _label(PendingOrdersSideFilter f) {
    return switch (f) {
      PendingOrdersSideFilter.all => 'All',
      PendingOrdersSideFilter.buy => 'Buy orders',
      PendingOrdersSideFilter.sell => 'Sell orders',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FILTER BY SIDE',
              textAlign: TextAlign.center,
              style: AppTypography.monoSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final f in PendingOrdersSideFilter.values)
              ListTile(
                key: ValueKey('pending-orders-filter-${f.name}'),
                title: Text(
                  _label(f),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: f == current
                    ? Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(f),
              ),
          ],
        ),
      ),
    );
  }
}
