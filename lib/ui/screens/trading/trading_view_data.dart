import 'package:flutter/foundation.dart';

import '../../../core/chart/price_chart_point.dart';

export '../../../core/chart/price_chart_point.dart' show PriceChartPoint;

@immutable
class OrderBookLevel {
  const OrderBookLevel({required this.price, required this.quantity});

  final double price;
  final int quantity;
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
    this.gameStartedAtUtc,
    this.tradingTimeRemaining,
  });

  final String gameTitle;
  final String description;
  final bool isViewerAdmin;
  final String currentPlayerId;

  /// When true and [tradingTimeRemaining] is non-null, shows a live countdown.
  final bool isTimed;
  final Duration? tradingTimeRemaining;

  /// Signed delta cash (USD); sign drives stat tile tint (green / red / neutral).
  final double deltaCash;

  /// Signed delta envelope count; sign drives stat tile tint.
  final double deltaEnvelopes;

  /// Bid side (price desc. in mock); depth bars use qty / max qty on that side.
  final List<OrderBookLevel> orderBookBids;

  /// Ask side (price asc. in mock).
  final List<OrderBookLevel> orderBookAsks;

  /// Headline market price (e.g. last trade).
  final double marketPrice;

  /// `(timeElapsed, price)` from executions, sorted ascending by time (plan **B9**).
  final List<PriceChartPoint> priceHistory;

  /// Elapsed since game start — drives horizontal division minutes (plan **B9**).
  final Duration chartSessionElapsed;

  /// Game start instant in UTC (Supabase `start_time`); used for touch tooltips only.
  final DateTime? gameStartedAtUtc;
}

@immutable
class GameTradingScenario {
  const GameTradingScenario({required this.data});

  final GameTradingViewData data;
}
