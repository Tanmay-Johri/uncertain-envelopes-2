import 'package:flutter/foundation.dart';

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
}

@immutable
class GameTradingScenario {
  const GameTradingScenario({required this.data});

  final GameTradingViewData data;
}
