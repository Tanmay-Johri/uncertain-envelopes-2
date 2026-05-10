import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/trading/personal_order.dart';
import '../../data/enums/end_condition.dart';
import '../../data/enums/order_status.dart';
import '../../data/models/execution.dart';
import '../../data/models/game_player.dart';
import '../../data/models/order.dart';
import '../../data/models/order_book.dart' as book_model;
import '../../ui/screens/trading/trading_view_data.dart';
import '../auth_provider.dart';
import '../clock_provider.dart';
import '../game_provider.dart';
import '../trading_provider.dart';
import 'lobby_view_data_provider.dart';

part 'trading_view_data_provider.g.dart';

/// Thrown when [tradingViewDataProvider] cannot build (e.g. not signed in).
class TradingViewDataException implements Exception {
  const TradingViewDataException(this.message);
  final String message;

  @override
  String toString() => 'TradingViewDataException($message)';
}

/// Maps a backend [Order] row into the trading UI’s [PersonalOrder] model.
PersonalOrder personalOrderFromOrder(Order o) {
  final side = o.type.isBuy ? PersonalOrderSide.buy : PersonalOrderSide.sell;
  final orderType =
      o.type.isLimit ? PersonalOrderType.limit : PersonalOrderType.market;
  return PersonalOrder(
    id: o.orderId,
    side: side,
    orderType: orderType,
    quantityInitial: o.quantityInitial,
    quantityCurrent: o.quantityCurrent,
    limitPrice: o.pricePerStock,
    status: _personalOrderStatusFromOrder(o.status),
    createdAt: o.orderCreatedAt,
  );
}

PersonalOrderStatus _personalOrderStatusFromOrder(OrderStatus s) {
  return switch (s) {
    OrderStatus.inQueue => PersonalOrderStatus.inQueue,
    OrderStatus.beingProcessed => PersonalOrderStatus.beingProcessed,
    OrderStatus.orderResting => PersonalOrderStatus.resting,
    OrderStatus.orderClosed => PersonalOrderStatus.filled,
    OrderStatus.cancelled => PersonalOrderStatus.cancelled,
    OrderStatus.gameEnded => PersonalOrderStatus.gameEnded,
  };
}

List<OrderBookLevel> _uiLevelsFromDataBook(List<book_model.OrderBookLevel> levels) {
  return [
    for (final l in levels)
      OrderBookLevel(price: l.price, quantity: l.totalQuantity),
  ];
}

List<TradeLogEntry> _tradeLogsFromExecutions({
  required List<Execution> executions,
  required Map<String, Order> ordersById,
  required String Function(String playerId) nameForPlayer,
}) {
  final sorted = [...executions]..sort((a, b) => a.executedAt.compareTo(b.executedAt));
  return [
    for (final e in sorted)
      TradeLogEntry(
        sellerName: nameForPlayer(
          ordersById[e.sellOrderId]?.createdByPlayerId ?? 'unknown',
        ),
        buyerName: nameForPlayer(
          ordersById[e.buyOrderId]?.createdByPlayerId ?? 'unknown',
        ),
        quantity: e.quantity,
        price: e.executionPrice,
        tradedAt: e.executedAt,
      ),
  ];
}

double _resolveMarketPrice({
  required List<Execution> executionsAsc,
  required double? gameLastTradedPrice,
  required List<OrderBookLevel> bids,
  required List<OrderBookLevel> asks,
}) {
  if (executionsAsc.isNotEmpty) {
    return executionsAsc.last.executionPrice;
  }
  if (gameLastTradedPrice != null) {
    return gameLastTradedPrice;
  }
  final mid = computeBidAskMidpoint(bids, asks);
  if (mid != null) return mid;
  return 100;
}

/// Trading dashboard snapshot for [gameId] (Phase 2B.5).
@riverpod
Future<GameTradingViewData> tradingViewData(Ref ref, String gameId) async {
  ref.watch(timerTickStreamProvider);
  final viewer = await ref.watch(authControllerProvider.future);
  if (viewer == null) {
    throw const TradingViewDataException(
      'Sign in to open the trading dashboard.',
    );
  }

  final session = await ref.watch(currentGameProvider(gameId).future);
  await ref.watch(ordersProvider(gameId).future);
  await ref.watch(executionsProvider(gameId).future);

  final game = session.game;
  final book = ref.watch(orderBookProvider(gameId));
  final bids = _uiLevelsFromDataBook(book.bids);
  final asks = _uiLevelsFromDataBook(book.asks);

  final orders = ref.watch(ordersProvider(gameId)).requireValue;
  final executionsAsc =
      ref.watch(executionsProvider(gameId)).requireValue;

  final ordersById = {for (final o in orders) o.orderId: o};
  final mine = orders
      .where((o) => o.createdByPlayerId == viewer.playerId)
      .map(personalOrderFromOrder)
      .toList();
  final personalSorted = personalOrdersSortedNewestFirst(mine);

  final priceHistory = ref.watch(executionHistoryProvider(gameId));
  final chartElapsed = ref.watch(chartSessionElapsedProvider(gameId));
  final secondsRemaining = ref.watch(gameSecondsRemainingProvider(gameId));

  GamePlayer? me;
  for (final p in session.players) {
    if (p.mapPlayerId == viewer.playerId) {
      me = p;
      break;
    }
  }

  final isTimed = game.endCondition == EndCondition.timed;
  final Duration? tradingRemaining = isTimed && secondsRemaining != null
      ? Duration(seconds: secondsRemaining)
      : null;

  final marketPrice = _resolveMarketPrice(
    executionsAsc: executionsAsc,
    gameLastTradedPrice: game.lastTradedPrice,
    bids: bids,
    asks: asks,
  );

  final tradeLogs = _tradeLogsFromExecutions(
    executions: executionsAsc,
    ordersById: ordersById,
    nameForPlayer: lobbyDisplayUsername,
  );

  return GameTradingViewData(
    gameTitle: game.gameName,
    description: game.gameDescription ?? '',
    isViewerAdmin: game.adminPlayerId == viewer.playerId,
    currentPlayerId: viewer.playerId,
    isTimed: isTimed,
    tradingTimeRemaining: tradingRemaining,
    deltaCash: me?.deltaCash ?? 0,
    deltaEnvelopes: (me?.deltaEnvelopes ?? 0).toDouble(),
    orderBookBids: bids,
    orderBookAsks: asks,
    marketPrice: marketPrice,
    priceHistory: priceHistory,
    chartSessionElapsed: chartElapsed,
    personalOrders: personalSorted,
    tradeLogs: tradeLogs,
    gameStartedAtUtc: game.startTime,
  );
}
