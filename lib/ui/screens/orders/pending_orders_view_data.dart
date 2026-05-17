import 'package:flutter/foundation.dart';

import '../../../core/trading/personal_order.dart';

@immutable
class PendingOrdersFilterState {
  const PendingOrdersFilterState({
    required this.directions,
    required this.selectedGameTitles,
  });

  /// **Empty** ⇒ do not filter by side (buy and sell both included).
  final Set<PersonalOrderSide> directions;

  /// **Empty** ⇒ do not filter by game (all games). **Non-empty** ⇒ keep
  /// rows whose [PendingOrderListItem.gameTitle] is in this set (OR).
  final Set<String> selectedGameTitles;

  /// Default: no direction filter, no game filter (everything visible).
  static const PendingOrdersFilterState initial = PendingOrdersFilterState(
    directions: {},
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

/// A game the signed-in player may place orders in (`games.game_state` =
/// `trading_started`). Drives the Pending Orders **Create new order** picker;
/// independent of whether the player already has resting orders.
@immutable
class TradingOrderTargetGame {
  const TradingOrderTargetGame({
    required this.gameId,
    required this.gameTitle,
    required this.gameDescription,
  });

  final String gameId;
  final String gameTitle;
  final String gameDescription;
}

/// Payload for [PendingOrdersRouteScreen]: pending rows plus games eligible
/// for creating new orders (joined + active trading).
@immutable
class PendingOrdersScreenData {
  const PendingOrdersScreenData({
    required this.items,
    required this.tradingGamesForNewOrder,
  });

  final List<PendingOrderListItem> items;
  final List<TradingOrderTargetGame> tradingGamesForNewOrder;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PendingOrdersScreenData &&
        listEquals(items, other.items) &&
        listEquals(tradingGamesForNewOrder, other.tradingGamesForNewOrder);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        Object.hashAll(tradingGamesForNewOrder),
      );
}

/// Unique [TradingOrderTargetGame]s derived from pending rows (dev/mock only).
List<TradingOrderTargetGame> tradingOrderTargetsFromPendingRows(
  List<PendingOrderListItem> rows,
) {
  final seen = <String>{};
  return [
    for (final e in rows)
      if (seen.add(e.gameId))
        TradingOrderTargetGame(
          gameId: e.gameId,
          gameTitle: e.gameTitle,
          gameDescription: e.gameDescription,
        ),
  ];
}

@immutable
class PendingOrderListItem {
  const PendingOrderListItem({
    required this.gameId,
    required this.gameTitle,
    required this.gameDescription,
    required this.order,
    this.isRecentlyClosed = false,
  });

  final String gameId;
  final String gameTitle;
  final String gameDescription;
  final PersonalOrder order;

  /// Terminal order still shown in the 1-minute grace window after close.
  final bool isRecentlyClosed;

  PendingOrderListItem copyWith({
    String? gameId,
    String? gameTitle,
    String? gameDescription,
    PersonalOrder? order,
    bool? isRecentlyClosed,
  }) {
    return PendingOrderListItem(
      gameId: gameId ?? this.gameId,
      gameTitle: gameTitle ?? this.gameTitle,
      gameDescription: gameDescription ?? this.gameDescription,
      order: order ?? this.order,
      isRecentlyClosed: isRecentlyClosed ?? this.isRecentlyClosed,
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
  var out = List<PendingOrderListItem>.from(items);
  if (filters.directions.isNotEmpty) {
    out = out
        .where((e) => filters.directions.contains(e.order.side))
        .toList();
  }
  if (filters.selectedGameTitles.isNotEmpty) {
    out = out
        .where((e) => filters.selectedGameTitles.contains(e.gameTitle))
        .toList();
  }
  return out;
}
