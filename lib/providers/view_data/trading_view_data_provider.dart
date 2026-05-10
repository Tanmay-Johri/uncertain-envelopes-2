import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/trading/personal_order.dart';
import '../../core/trading/personal_order_from_order.dart';
import '../../data/enums/end_condition.dart';
import '../../data/models/execution.dart';
import '../../data/models/game_player.dart';
import '../../data/models/order.dart';
import '../../data/models/order_book.dart' as book_model;
import '../../ui/screens/trading/trading_view_data.dart';
import '../auth_provider.dart';
import '../game_provider.dart';
import '../player_repository_provider.dart';
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

double? _resolveMarketPrice({
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
  return null;
}

/// Trading dashboard snapshot for [gameId] (Phase 2B.5).
///
/// Does **not** subscribe to the timer tick. Re-runs only when session, orders,
/// executions, or auth change. The countdown ticks locally inside
/// [CountdownTimer] from a one-shot seconds-remaining snapshot read here, and
/// the chart's session-elapsed is also a one-shot snapshot. This prevents the
/// trading screen from flickering once per second while still updating
/// instantly whenever real backend data changes.
@riverpod
Future<GameTradingViewData> tradingViewData(Ref ref, String gameId) async {
  final viewer = await ref.watch(authControllerProvider.future);
  if (viewer == null) {
    throw const TradingViewDataException(
      'Sign in to open the trading dashboard.',
    );
  }

  final session = await ref.watch(currentGameProvider(gameId).future);
  await ref.watch(ordersProvider(gameId).future);
  await ref.watch(executionsProvider(gameId).future);
  final mineOrders = await ref.watch(
    personalOrdersProvider(gameId: gameId, playerId: viewer.playerId).future,
  );

  final game = session.game;
  final book = ref.watch(orderBookProvider(gameId));
  final bids = _uiLevelsFromDataBook(book.bids);
  final asks = _uiLevelsFromDataBook(book.asks);

  final orders = ref.watch(ordersProvider(gameId)).requireValue;
  final executionsAsc =
      ref.watch(executionsProvider(gameId)).requireValue;

  final ordersById = {for (final o in orders) o.orderId: o};
  final personalSorted =
      personalOrdersSortedNewestFirst(mineOrders.map(personalOrderFromOrder).toList());

  final priceHistory = ref.watch(executionHistoryProvider(gameId));
  // ref.read so timer ticks do not re-run this future (fixes trading flicker).
  // chartSessionElapsed and secondsRemaining both depend on timerTickStream;
  // we snapshot them at build time and let the UI tick locally.
  final chartElapsed = ref.read(chartSessionElapsedProvider(gameId));
  final secondsRemaining = ref.read(gameSecondsRemainingProvider(gameId));

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

  final tradeParticipantIds = <String>{
    for (final p in session.players) p.mapPlayerId,
    for (final e in executionsAsc) ...[
      if (ordersById[e.sellOrderId] != null)
        ordersById[e.sellOrderId]!.createdByPlayerId,
      if (ordersById[e.buyOrderId] != null)
        ordersById[e.buyOrderId]!.createdByPlayerId,
    ],
  };
  final profilesById =
      await ref.read(playerRepositoryProvider).fetchProfilesByIds(
            tradeParticipantIds.toList(),
          );

  final tradeLogs = _tradeLogsFromExecutions(
    executions: executionsAsc,
    ordersById: ordersById,
    nameForPlayer: (id) => displayUsernameForPlayer(id, profilesById),
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
