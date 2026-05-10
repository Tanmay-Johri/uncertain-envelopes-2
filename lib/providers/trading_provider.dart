import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/chart/chart_axis.dart';
import '../core/chart/price_chart_point.dart';
import '../data/enums/command_status.dart';
import '../data/enums/command_type.dart';
import '../data/enums/order_status.dart';
import '../data/enums/order_type.dart';
import '../data/models/command.dart';
import '../data/models/execution.dart';
import '../data/models/order.dart';
import '../data/models/order_book.dart';
import 'clock_provider.dart';
import 'command_repository_provider.dart';
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

/// Non-terminal `create_order` commands for [gameId] (all players).
///
/// Seeded from [CommandRepository.fetchPendingCreateOrderCommandsForGame],
/// then updated by [GameRealtimeService] `commands` realtime events and
/// [RiverpodRealtimeTarget.refreshAll] (B-GAP-1b).
@riverpod
class PendingCreateOrderCommands extends _$PendingCreateOrderCommands {
  @override
  Future<List<Command>> build(String gameId) {
    final repo = ref.watch(commandRepositoryProvider);
    return repo.fetchPendingCreateOrderCommandsForGame(gameId);
  }

  /// Applies INSERT/UPDATE payloads from Supabase Realtime (or tests).
  void mergeRealtime(Command cmd) {
    if (cmd.commandGameId != gameId) return;
    if (cmd.commandType != CommandType.createOrder) return;
    if (cmd.playerId == null) return;

    final current = state.valueOrNull;
    if (current == null) return;

    if (cmd.commandStatus.isTerminal) {
      final next =
          current.where((c) => c.commandId != cmd.commandId).toList();
      state = AsyncValue.data(List.unmodifiable(next));
      return;
    }

    final replaced = <Command>[
      for (final c in current)
        if (c.commandId != cmd.commandId) c,
      cmd,
    ]..sort((a, b) => b.commandCreatedAt.compareTo(a.commandCreatedAt));
    state = AsyncValue.data(List.unmodifiable(replaced));
  }

  void removeByCommandId(String commandId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      List.unmodifiable(
        current.where((c) => c.commandId != commandId).toList(),
      ),
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final repo = ref.read(commandRepositoryProvider);
    state = await AsyncValue.guard(
      () => repo.fetchPendingCreateOrderCommandsForGame(gameId),
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

/// Synthetic `orders.order_id` for a row materialised only from a pending
/// `create_order` command (B-GAP-1).
String pendingCreateOrderPlaceholderOrderId(String commandId) =>
    'cmd:$commandId';

Order? orderFromPendingCreateCommand(Command cmd, String playerId) {
  if (cmd.commandType != CommandType.createOrder) return null;
  if (cmd.playerId != playerId) return null;
  final gid = cmd.commandGameId;
  if (gid == null) return null;

  final p = cmd.payload;
  final type = OrderType.fromWire(p['type'] as String);
  final qtyRaw = p['quantity_initial'];
  final qty = qtyRaw is int ? qtyRaw : (qtyRaw as num).toInt();
  final priceRaw = p['price_per_stock'];
  final double? price = priceRaw == null ? null : (priceRaw as num).toDouble();

  final orderStatus = switch (cmd.commandStatus) {
    CommandStatus.pending => OrderStatus.inQueue,
    CommandStatus.claimed => OrderStatus.beingProcessed,
    CommandStatus.failed => OrderStatus.beingProcessed,
    CommandStatus.processed => OrderStatus.inQueue,
    CommandStatus.rejected => OrderStatus.inQueue,
  };

  return Order(
    orderId: pendingCreateOrderPlaceholderOrderId(cmd.commandId),
    createdByPlayerId: playerId,
    gameId: gid,
    type: type,
    quantityInitial: qty,
    quantityCurrent: qty,
    pricePerStock: price,
    status: orderStatus,
    orderCreatedAt: cmd.commandCreatedAt,
    orderUpdatedAt: cmd.commandCreatedAt,
  );
}

/// Orders belonging to [playerId] within [gameId], merged with non-terminal
/// `create_order` commands from [pendingCreateOrderCommandsProvider] as placeholder
/// rows (B-GAP-1 / B-GAP-1b). Newest first.
@riverpod
Future<List<Order>> personalOrders(
  Ref ref, {
  required String gameId,
  required String playerId,
}) async {
  final realOrders = await ref.watch(ordersProvider(gameId).future);
  final pendingAll =
      ref.watch(pendingCreateOrderCommandsProvider(gameId)).valueOrNull ??
      const <Command>[];
  final pending = pendingAll
      .where(
        (c) =>
            c.playerId == playerId && c.commandType == CommandType.createOrder,
      )
      .toList();

  final mineReal = realOrders
      .where((o) => o.createdByPlayerId == playerId)
      .toList();

  final synthetic = <Order>[];
  for (final c in pending) {
    final o = orderFromPendingCreateCommand(c, playerId);
    if (o != null) synthetic.add(o);
  }

  final merged = [...mineReal, ...synthetic]
    ..sort((a, b) => b.orderCreatedAt.compareTo(a.orderCreatedAt));
  return List.unmodifiable(merged);
}

/// (timeElapsed, price) datapoints for the trading chart. Returns an
/// empty list when the game has not started yet (no start_time), when
/// the snapshot is still loading, or when no executions exist yet.
///
/// Emits the canonical [PriceChartPoint] type owned by `lib/core/chart/`,
/// which is also what [PriceChart] (the UI widget) consumes — so the
/// provider output flows straight into the chart with no conversion.
@riverpod
List<PriceChartPoint> executionHistory(Ref ref, String gameId) {
  final snap = ref.watch(currentGameProvider(gameId));
  final start = snap.valueOrNull?.game.startTime;
  if (start == null) return const [];

  final executions =
      ref.watch(executionsProvider(gameId)).valueOrNull ?? const [];

  final points = executions
      .map(
        (e) => PriceChartPoint(
          timeElapsed: e.executedAt.difference(start),
          price: e.executionPrice,
        ),
      )
      .toList()
    ..sort((a, b) => a.timeElapsed.compareTo(b.timeElapsed));
  return List.unmodifiable(points);
}

/// Wall-clock elapsed time the chart should cover (the "session" duration).
///
/// PRD elapsed rules:
/// - Before start_time exists: synthesise 1 minute so the axis renders.
/// - While trading is active: elapsed = now() - start_time
/// - After trading ended: elapsed = end_time_actual - start_time
///
/// Exposed as its own provider (not just inlined in [chartAxis]) because
/// `GameTradingViewData.chartSessionElapsed` consumes exactly this value
/// at INT1 wiring time, and [PriceChart] derives its tooltip x-axis from
/// the same number.
@riverpod
Duration chartSessionElapsed(Ref ref, String gameId) {
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
  return elapsed.isNegative ? Duration.zero : elapsed;
}

/// Chart axis configuration derived from executionHistory + session
/// elapsed time. Delegates to [ChartAxisConfig.fromExecutionHistory] —
/// the same factory the trading screen calls inline today — so the
/// provider-driven path is byte-identical to the mock-driven path the
/// UI was tuned against.
@riverpod
ChartAxisConfig chartAxis(Ref ref, String gameId) {
  final elapsed = ref.watch(chartSessionElapsedProvider(gameId));
  final points = ref.watch(executionHistoryProvider(gameId));
  return ChartAxisConfig.fromExecutionHistory(
    sessionElapsed: elapsed,
    points: points,
  );
}
