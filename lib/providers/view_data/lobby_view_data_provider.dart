import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/end_condition.dart';
import '../../data/enums/game_security.dart';
import '../../data/enums/game_state.dart';
import '../../data/enums/is_ranked.dart';
import '../../data/models/game_session_state.dart';
import '../../ui/screens/lobby/lobby_view_data.dart';
import '../auth_provider.dart';
import '../clock_provider.dart';
import '../game_provider.dart';

part 'lobby_view_data_provider.g.dart';

/// Thrown when [lobbyViewDataProvider] cannot build (e.g. not signed in).
class LobbyViewDataException implements Exception {
  const LobbyViewDataException(this.message);
  final String message;

  @override
  String toString() => 'LobbyViewDataException($message)';
}

/// Fallback display name when `games_players` has no joined `players.username`.
String lobbyDisplayUsername(String playerId) {
  final compact = playerId.replaceAll('-', '');
  final tail = compact.length >= 4
      ? compact.substring(compact.length - 4)
      : (compact.isEmpty ? '?' : compact);
  return 'Player $tail';
}

/// Two-letter initials derived from [playerId] (stable, ASCII).
String lobbyInitials(String playerId) {
  final alnum = playerId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (alnum.length >= 2) {
    return alnum.substring(0, 2).toUpperCase();
  }
  if (alnum.isNotEmpty) {
    return '${alnum[0]}?'.toUpperCase();
  }
  return '?';
}

/// Maps a loaded session + viewer id into [GameLobbyScenario] (Phase 2B.4).
GameLobbyScenario lobbyScenarioFromSession({
  required GameSessionState session,
  required String viewerPlayerId,
  int? tradingSecondsRemaining,
}) {
  final game = session.game;
  final players = [...session.players]
    ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  final phase = game.gameState == GameState.created
      ? GameLobbyPhase.preStart
      : GameLobbyPhase.trading;

  final Duration? tradingRemaining =
      game.endCondition == EndCondition.timed && tradingSecondsRemaining != null
          ? Duration(seconds: tradingSecondsRemaining)
          : null;

  return GameLobbyScenario(
    data: GameLobbyViewData(
      gameTitle: game.gameName,
      description: game.gameDescription ?? '',
      joiningCodeRaw: game.joiningCode,
      isPublic: game.gameSecurity == GameSecurity.public,
      isRanked: game.isRanked == IsRanked.ranked,
      maxPlayers: game.gameMaxPlayers,
      players: [
        for (final p in players)
          LobbyPlayerView(
            id: p.mapPlayerId,
            username: lobbyDisplayUsername(p.mapPlayerId),
            initials: lobbyInitials(p.mapPlayerId),
            isGameAdmin: p.isAdmin,
          ),
      ],
      isTimed: game.endCondition == EndCondition.timed,
      tradingTimeRemaining: tradingRemaining,
    ),
    phase: phase,
    currentPlayerId: viewerPlayerId,
    isViewerAdmin: game.adminPlayerId == viewerPlayerId,
  );
}

/// Lobby header, roster, and phase for [gameId] (Phase 2B.4).
@riverpod
Future<GameLobbyScenario> lobbyViewData(Ref ref, String gameId) async {
  ref.watch(timerTickStreamProvider);
  final viewer = await ref.watch(authControllerProvider.future);
  if (viewer == null) {
    throw const LobbyViewDataException('Sign in to view this lobby.');
  }

  final snapshot = await ref.watch(currentGameProvider(gameId).future);
  final seconds = ref.watch(gameSecondsRemainingProvider(gameId));

  return lobbyScenarioFromSession(
    session: snapshot,
    viewerPlayerId: viewer.playerId,
    tradingSecondsRemaining: seconds,
  );
}
