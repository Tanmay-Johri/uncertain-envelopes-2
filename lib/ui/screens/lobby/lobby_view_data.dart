import 'package:flutter/foundation.dart';

/// Lobby lifecycle for mock UI: pre-trading vs trading (enter game).
enum GameLobbyPhase {
  /// `created` — admin can start/end; kicks allowed for admin.
  preStart,

  /// `trading_started` — primary action is enter trading.
  trading,
}

@immutable
class LobbyPlayerView {
  const LobbyPlayerView({
    required this.id,
    required this.username,
    required this.initials,
    required this.isGameAdmin,
  });

  final String id;
  final String username;
  final String initials;
  final bool isGameAdmin;
}

@immutable
class GameLobbyViewData {
  const GameLobbyViewData({
    required this.gameTitle,
    required this.description,
    required this.joiningCodeRaw,
    required this.isPublic,
    required this.isRanked,
    required this.maxPlayers,
    required this.players,
    required this.isTimed,
    this.tradingTimeRemaining,
    this.tradingDeadlineUtc,
  });

  final String gameTitle;
  final String description;

  /// Uppercase alphanumeric, no spaces (e.g. `V8JAJ`).
  final String joiningCodeRaw;
  final bool isPublic;
  final bool isRanked;
  final int maxPlayers;
  final List<LobbyPlayerView> players;
  final bool isTimed;

  /// Pre-start: planned trading duration. Trading phase: fallback only when no
  /// [tradingDeadlineUtc].
  final Duration? tradingTimeRemaining;

  /// During trading (`games.end_time_decided`) — canonical countdown end.
  final DateTime? tradingDeadlineUtc;
}

/// Joins characters with spaces for the large mono display (e.g. `V 8 J A J`).
String formatJoiningCodeDisplay(String joiningCodeRaw) {
  final compact = joiningCodeRaw.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (compact.isEmpty) return '';
  return compact.split('').join(' ');
}

@immutable
class GameLobbyScenario {
  const GameLobbyScenario({
    required this.data,
    required this.phase,
    required this.currentPlayerId,
    required this.isViewerAdmin,
  });

  final GameLobbyViewData data;
  final GameLobbyPhase phase;
  final String currentPlayerId;
  final bool isViewerAdmin;
}

/// True when [viewerId] matches a row in [data.players] (viewer has joined).
bool lobbyViewerIsInPlayerList(GameLobbyViewData data, String viewerId) {
  return data.players.any((p) => p.id == viewerId);
}
