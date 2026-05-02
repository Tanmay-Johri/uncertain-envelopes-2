import 'package:flutter/foundation.dart';

import '../../../core/trading/personal_order.dart';

/// Filter shown from the **Filter** control (Stream C9).
enum PendingOrdersSideFilter {
  all,
  buy,
  sell,
}

@immutable
class PendingOrderListItem {
  const PendingOrderListItem({
    required this.gameTitle,
    required this.gameDescription,
    required this.order,
  });

  final String gameTitle;
  final String gameDescription;
  final PersonalOrder order;

  PendingOrderListItem copyWith({
    String? gameTitle,
    String? gameDescription,
    PersonalOrder? order,
  }) {
    return PendingOrderListItem(
      gameTitle: gameTitle ?? this.gameTitle,
      gameDescription: gameDescription ?? this.gameDescription,
      order: order ?? this.order,
    );
  }
}

/// Newest [PersonalOrder.createdAt] first; missing timestamps sort last
/// (stable tie-break: [PersonalOrder.id]).
List<PendingOrderListItem> pendingOrderListItemsSortedNewestFirst(
  List<PendingOrderListItem> items,
) {
  final copy = List<PendingOrderListItem>.from(items);
  copy.sort((a, b) {
    final ta = a.order.createdAt;
    final tb = b.order.createdAt;
    if (ta == null && tb == null) return a.order.id.compareTo(b.order.id);
    if (ta == null) return 1;
    if (tb == null) return -1;
    final cmp = tb.compareTo(ta);
    if (cmp != 0) return cmp;
    return a.order.id.compareTo(b.order.id);
  });
  return copy;
}

List<PendingOrderListItem> applyPendingOrdersSideFilter(
  List<PendingOrderListItem> items,
  PendingOrdersSideFilter filter,
) {
  return switch (filter) {
    PendingOrdersSideFilter.all => List<PendingOrderListItem>.from(items),
    PendingOrdersSideFilter.buy =>
      items.where((e) => e.order.side == PersonalOrderSide.buy).toList(),
    PendingOrdersSideFilter.sell =>
      items.where((e) => e.order.side == PersonalOrderSide.sell).toList(),
  };
}
