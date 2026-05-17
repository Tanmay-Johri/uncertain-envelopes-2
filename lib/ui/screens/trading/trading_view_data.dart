import 'package:flutter/foundation.dart';

import '../../../core/chart/price_chart_point.dart';
import '../../../core/trading/personal_order.dart';

export '../../../core/chart/price_chart_point.dart' show PriceChartPoint;
export '../../../core/trading/personal_order.dart'
    show
        PersonalOrder,
        PersonalOrderSide,
        PersonalOrderStatus,
        PersonalOrderType,
        personalOrderClearsCancellationPending;

/// One executed trade between two players, shown in the transaction log.
@immutable
class TradeLogEntry {
  const TradeLogEntry({
    required this.sellerName,
    required this.sellerPlayerId,
    required this.buyerName,
    required this.buyerPlayerId,
    required this.quantity,
    required this.price,
    this.tradedAt,
  });

  /// Display name of the player who sold (gave envelopes).
  final String sellerName;

  /// [GamePlayer.mapPlayerId] / auth player id for the sell-side order owner.
  final String sellerPlayerId;

  /// Display name of the player who bought (received envelopes).
  final String buyerName;

  /// Player id for the buy-side order owner.
  final String buyerPlayerId;

  /// Number of envelopes exchanged.
  final int quantity;

  /// Execution price per envelope (USD).
  final double price;

  /// Wall-clock UTC when the trade executed (`players` / Supabase). Shown in
  /// local time in the transaction log.
  final DateTime? tradedAt;
}

/// True when [viewerPlayerId] owns the buy or sell order for this execution.
bool tradeLogEntryInvolvesPlayer(TradeLogEntry entry, String viewerPlayerId) {
  return entry.sellerPlayerId == viewerPlayerId ||
      entry.buyerPlayerId == viewerPlayerId;
}

@immutable
class OrderBookLevel {
  const OrderBookLevel({required this.price, required this.quantity});

  final double price;
  final int quantity;
}

/// Midpoint `(best bid + best ask) / 2` when both sides have at least one
/// level; otherwise `null`.
///
/// Best bid is the **maximum** bid price; best ask is the **minimum** ask price
/// (robust even if lists are not sorted).
double? computeBidAskMidpoint(
  List<OrderBookLevel> bids,
  List<OrderBookLevel> asks,
) {
  if (bids.isEmpty || asks.isEmpty) return null;
  final bestBid = bids.map((e) => e.price).reduce((a, b) => a > b ? a : b);
  final bestAsk = asks.map((e) => e.price).reduce((a, b) => a < b ? a : b);
  return (bestBid + bestAsk) / 2;
}

/// Immutable snapshot for the trading dashboard (mock UI; Phase 2 replaces
/// with provider-driven state).
@immutable
class GameTradingViewData {
  const GameTradingViewData({
    required this.gameTitle,
    required this.description,
    required this.isViewerAdmin,
    required this.currentPlayerId,
    required this.isTimed,
    required this.deltaCash,
    required this.deltaEnvelopes,
    required this.orderBookBids,
    required this.orderBookAsks,
    required this.marketPrice,
    required this.priceHistory,
    required this.chartSessionElapsed,
    this.personalOrders = const [],
    this.tradeLogs = const [],
    this.gameStartedAtUtc,
    this.tradingTimeRemaining,
    this.tradingDeadlineUtc,
  });

  final String gameTitle;
  final String description;
  final bool isViewerAdmin;
  final String currentPlayerId;

  /// When true and ([tradingDeadlineUtc] or [tradingTimeRemaining]) is set,
  /// shows a live countdown.
  final bool isTimed;
  final Duration? tradingTimeRemaining;

  /// DB `end_time_decided` — drives [CountdownTimer] directly (canonical).
  final DateTime? tradingDeadlineUtc;

  /// Signed delta cash (USD); sign drives stat tile tint (green / red / neutral).
  final double deltaCash;

  /// Signed delta envelope count; sign drives stat tile tint.
  final double deltaEnvelopes;

  /// Bid side (price desc. in mock); depth bars use qty / max qty on that side.
  final List<OrderBookLevel> orderBookBids;

  /// Ask side (price asc. in mock).
  final List<OrderBookLevel> orderBookAsks;

  /// Headline market price (e.g. last trade or bid–ask mid). `null` when unknown
  /// (no trades, no stored last price, incomplete book) — show `-` in the UI.
  final double? marketPrice;

  /// `(timeElapsed, price)` from executions, sorted ascending by time (plan **B9**).
  final List<PriceChartPoint> priceHistory;

  /// Elapsed since game start — drives horizontal division minutes (plan **B9**).
  final Duration chartSessionElapsed;

  /// Player’s own orders for **Active orders** (C6 mock; Phase 2 from providers).
  final List<PersonalOrder> personalOrders;

  /// Executed trades for the transaction log, **newest first**. Empty until Phase 2.
  final List<TradeLogEntry> tradeLogs;

  /// Game start instant in UTC (Supabase `start_time`); used for touch tooltips only.
  final DateTime? gameStartedAtUtc;
}

@immutable
class GameTradingScenario {
  const GameTradingScenario({required this.data});

  final GameTradingViewData data;
}
