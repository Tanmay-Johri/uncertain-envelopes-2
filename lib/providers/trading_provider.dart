import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/enums/order_status.dart';
import '../data/models/chart_axis.dart';
import '../data/models/execution.dart';
import '../data/models/order.dart';
import '../data/models/order_book.dart';
import 'clock_provider.dart';
import 'game_provider.dart';
import 'trading_repository_providers.dart';

part 'trading_provider.g.dart';

/// All orders for a game. Fed initially by [OrderRepository], then updated
/// by [GameRealtimeService] (B10) via the mutation hooks below.
@riverpod
class Orders extends _$Orders {
  @override
  Future<List<Order>> build(String gameId) {
    final repo = ref.watch(orderRepositoryProvider);
    return repo.fetchOrdersForGame(gameId);
  }

  /// Upsert by `order_id`. Used for realtime INSERT and UPDATE events.
  void upsert(Order order) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (order.gameId != gameId) return;
    final replaced = [
      for (final o in current)
        if (o.orderId == order.orderId) order else o,
    ];
    if (!current.any((o) => o.orderId == order.orderId)) {
      replaced.add(order);
    }
    state = AsyncValue.data(replaced);
  }

  void remove(String orderId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.where((o) => o.orderId != orderId).toList(),
    );
  }

  void replaceAll(List<Order> orders) {
    state = AsyncValue.data(List.unmodifiable(orders));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final repo = ref.read(orderRepositoryProvider);
    state = await AsyncValue.guard(
      () => repo.fetchOrdersForGame(gameId),
    );
  }
}

/// All executions for a game, sorted ascending by `executed_at`.
@riverpod
class Executions extends _$Executions {
  @override
  Future<List<Execution>> build(String gameId) {
    final repo = ref.watch(executionRepositoryProvider);
    return repo.fetchExecutionsForGame(gameId);
  }

  void add(Execution execution) {
    final current = state.valueOrNull;
    if (current == null) return;
    if (execution.executionsGameId != gameId) return;
    // De-dupe by id in case realtime + polling both deliver the same
    // row — the chart must never show doubled points.
    if (current.any((e) => e.executionsId == execution.executionsId)) {
      return;
    }
    final next = [...current, execution]
      ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
    state = AsyncValue.data(List.unmodifiable(next));
  }

  void replaceAll(List<Execution> executions) {
    state = AsyncValue.data(List.unmodifiable(executions));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final repo = ref.read(executionRepositoryProvider);
    state = await AsyncValue.guard(
      () => repo.fetchExecutionsForGame(gameId),
    );
  }
}

/// Aggregated resting-order book: bids desc by price, asks asc by price.
///
/// Only orders with status [OrderStatus.orderResting] and a non-null
/// `pricePerStock` participate. Market orders never rest, so they are
/// implicitly excluded.
@riverpod
OrderBook orderBook(Ref ref, String gameId) {
  final orders = ref.watch(ordersProvider(gameId)).valueOrNull ?? const [];

  final bidByPrice = <double, int>{};
  final askByPrice = <double, int>{};
  for (final order in orders) {
    if (order.status != OrderStatus.orderResting) continue;
    final price = order.pricePerStock;
    if (price == null) continue;
    if (order.type.isBuy) {
      bidByPrice[price] = (bidByPrice[price] ?? 0) + order.quantityCurrent;
    } else if (order.type.isSell) {
      askByPrice[price] = (askByPrice[price] ?? 0) + order.quantityCurrent;
    }
  }

  final bidLevels = bidByPrice.entries
      .map((e) => OrderBookLevel(price: e.key, totalQuantity: e.value))
      .toList()
    ..sort((a, b) => b.price.compareTo(a.price));
  final askLevels = askByPrice.entries
      .map((e) => OrderBookLevel(price: e.key, totalQuantity: e.value))
      .toList()
    ..sort((a, b) => a.price.compareTo(b.price));

  return OrderBook(bids: bidLevels, asks: askLevels);
}

/// Orders belonging to [playerId] within [gameId]. Sorted newest first,
/// per PRD §Personal Orders intent.
///
/// Known gap: the PRD also wants pending `create_order` commands that
/// have not yet produced an orders row to show up as "in queue"
/// placeholders. That requires a command-status fetch we haven't
/// wired yet; tracked separately. This provider currently surfaces
/// only the orders table.
@riverpod
List<Order> personalOrders(
  Ref ref, {
  required String gameId,
  required String playerId,
}) {
  final orders = ref.watch(ordersProvider(gameId)).valueOrNull ?? const [];
  final mine = orders
      .where((o) => o.createdByPlayerId == playerId)
      .toList()
    ..sort((a, b) => b.orderCreatedAt.compareTo(a.orderCreatedAt));
  return List.unmodifiable(mine);
}

/// (timeElapsed, price) datapoints for the trading chart. Returns an
/// empty list when the game has not started yet (no start_time), when
/// the snapshot is still loading, or when no executions exist yet.
@riverpod
List<ExecutionPoint> executionHistory(Ref ref, String gameId) {
  final snap = ref.watch(currentGameProvider(gameId));
  final start = snap.valueOrNull?.game.startTime;
  if (start == null) return const [];

  final executions =
      ref.watch(executionsProvider(gameId)).valueOrNull ?? const [];

  final points = executions
      .map(
        (e) => ExecutionPoint(
          timeElapsed: e.executedAt.difference(start),
          price: e.executionPrice,
        ),
      )
      .toList()
    ..sort((a, b) => a.timeElapsed.compareTo(b.timeElapsed));
  return List.unmodifiable(points);
}

/// Chart axis configuration derived from executionHistory + game times.
///
/// Elapsed logic matches the PRD:
/// - While trading is active: elapsed = now() - start_time
/// - After trading ended: elapsed = end_time_actual - start_time
/// - Before start: null (the chart is rendered empty with default axes)
@riverpod
ChartAxisConfig chartAxis(Ref ref, String gameId) {
  final snap = ref.watch(currentGameProvider(gameId));
  final game = snap.valueOrNull?.game;
  final start = game?.startTime;

  final now = ref.watch(timerTickStreamProvider).valueOrNull ??
      ref.read(clockProvider)();

  Duration elapsed;
  if (game == null || start == null) {
    elapsed = const Duration(minutes: 1);
  } else if (game.endTimeActual != null) {
    elapsed = game.endTimeActual!.difference(start);
  } else {
    elapsed = now.difference(start);
  }
  if (elapsed.isNegative) {
    elapsed = Duration.zero;
  }

  final divisionMinutes = pickDivisionMinutes(elapsed);

  final points = ref.watch(executionHistoryProvider(gameId));
  double minPrice;
  double maxPrice;
  if (points.isEmpty) {
    minPrice = 0;
    maxPrice = 1;
  } else {
    final prices = points.map((p) => p.price);
    minPrice = prices.min;
    maxPrice = prices.max;
    if (minPrice == maxPrice) {
      // Single-price axis: widen slightly so the line isn't exactly on a
      // grid line and still visible.
      final pad = minPrice == 0 ? 1.0 : minPrice * 0.1;
      minPrice -= pad;
      maxPrice += pad;
    } else {
      final pad = (maxPrice - minPrice) * 0.1;
      minPrice -= pad;
      maxPrice += pad;
    }
  }

  return ChartAxisConfig(
    divisionMinutes: divisionMinutes,
    divisionCount: 6,
    totalElapsedSeconds: elapsed.inSeconds,
    minPrice: minPrice,
    maxPrice: maxPrice,
  );
}
