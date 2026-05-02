import 'package:flutter/foundation.dart';

import '../../../core/trading/personal_order.dart';

@immutable
class PendingOrdersFilterState {
  const PendingOrdersFilterState({
    required this.directions,
    required this.selectedGameTitles,
  });

  /// Buys and/or sells. **Empty** ⇒ no orders pass the direction gate.
  final Set<PersonalOrderSide> directions;

  /// **Empty** ⇒ do not filter by game (all games). **Non-empty** ⇒ keep
  /// rows whose [PendingOrderListItem.gameTitle] is in this set (OR).
  final Set<String> selectedGameTitles;

  /// Default: both sides; no game restriction.
  static const PendingOrdersFilterState initial = PendingOrdersFilterState(
    directions: {PersonalOrderSide.buy, PersonalOrderSide.sell},
    selectedGameTitles: {},
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingOrdersFilterState &&
        setEquals(directions, other.directions) &&
        setEquals(selectedGameTitles, other.selectedGameTitles);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(directions),
        Object.hashAll(selectedGameTitles),
      );
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

List<PendingOrderListItem> applyPendingOrdersFilters(
  List<PendingOrderListItem> items,
  PendingOrdersFilterState filters,
) {
  if (filters.directions.isEmpty) {
    return [];
  }
  var out = items
      .where((e) => filters.directions.contains(e.order.side))
      .toList();
  if (filters.selectedGameTitles.isNotEmpty) {
    out = out
        .where((e) => filters.selectedGameTitles.contains(e.gameTitle))
        .toList();
  }
  return out;
}
