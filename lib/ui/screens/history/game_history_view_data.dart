import 'package:flutter/foundation.dart';

/// One player's final PnL row inside an expanded history entry.
@immutable
class GameHistoryPlayerResult {
  const GameHistoryPlayerResult({
    required this.playerId,
    required this.displayName,
    required this.pnl,
  });

  final String playerId;
  final String displayName;

  /// Final PnL for this player. Positive = profit, negative = loss.
  final double pnl;
}

/// One completed game in the viewer's history.
@immutable
class GameHistoryEntry {
  const GameHistoryEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.viewerPnl,
    required this.securityType,
    required this.isRanked,
    required this.adminName,
    required this.envelopePriceUsd,
    required this.startedAt,
    required this.endedAt,
    required this.playerResults,
  });

  /// Stable unique id — used as the expand/collapse key.
  final String id;

  final String title;
  final String description;

  /// The current viewer's own PnL in this game.
  /// Positive → green, negative → red, zero → neutral.
  final double viewerPnl;

  /// "Public" or "Private".
  final String securityType;

  /// true → "Ranked", false → "Casual".
  final bool isRanked;

  /// Displayed as "@adminName".
  final String adminName;

  /// null when the envelope price was never set (e.g. discarded game).
  final double? envelopePriceUsd;

  /// When the game started. null for legacy / unknown.
  final DateTime? startedAt;

  /// When the game ended. null for legacy / unknown.
  final DateTime? endedAt;

  /// All players sorted by PnL descending (caller's responsibility).
  final List<GameHistoryPlayerResult> playerResults;
}
