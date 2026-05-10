import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/end_condition.dart';
import '../../data/enums/game_security.dart';
import '../../data/enums/game_state.dart';
import '../../data/enums/is_ranked.dart';
import '../../data/models/game_session_state.dart';
import '../../data/models/player.dart';
import '../../ui/screens/lobby/lobby_view_data.dart';
import '../auth_provider.dart';
import '../game_provider.dart';
import '../player_repository_provider.dart';

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
///
/// [profilesByPlayerId] supplies real usernames; falls back to
/// [lobbyDisplayUsername] when an id is missing (e.g. profile fetch failed).
///
/// [tradingSecondsRemaining] is a one-shot snapshot at build time; the
/// [game_lobby_screen] then ticks locally via `CountdownTimer` so this
/// provider does **not** rebuild every second.
GameLobbyScenario lobbyScenarioFromSession({
  required GameSessionState session,
  required String viewerPlayerId,
  Map<String, Player> profilesByPlayerId = const {},
  int? tradingSecondsRemaining,
}) {
  final game = session.game;
  final players = [...session.players]
    ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

  final phase = game.gameState == GameState.created
      ? GameLobbyPhase.preStart
      : GameLobbyPhase.trading;

  Duration? tradingRemaining;
  if (game.endCondition == EndCondition.timed) {
    if (phase == GameLobbyPhase.preStart) {
      final secs = game.totalDecidedDurationSeconds;
      if (secs != null && secs > 0) {
        tradingRemaining = Duration(seconds: secs);
      }
    } else if (tradingSecondsRemaining != null) {
      tradingRemaining = Duration(seconds: tradingSecondsRemaining);
    }
  }

  String usernameFor(String playerId) {
    final p = profilesByPlayerId[playerId];
    if (p != null && p.username.trim().isNotEmpty) return p.username;
    return lobbyDisplayUsername(playerId);
  }

  String initialsFor(String playerId) {
    final p = profilesByPlayerId[playerId];
    final source = (p != null && p.username.trim().isNotEmpty)
        ? p.username
        : playerId;
    final alnum = source.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (alnum.length >= 2) return alnum.substring(0, 2).toUpperCase();
    if (alnum.isNotEmpty) return '${alnum[0]}?'.toUpperCase();
    return '?';
  }

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
            username: usernameFor(p.mapPlayerId),
            initials: initialsFor(p.mapPlayerId),
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
///
/// Does **not** subscribe to the timer tick so the future runs only when
/// session data changes (auth / realtime / membership). The countdown is
/// rendered by the `CountdownTimer` widget which ticks locally from a
/// one-shot seconds-remaining snapshot read here.
@riverpod
Future<GameLobbyScenario> lobbyViewData(Ref ref, String gameId) async {
  final viewer = await ref.watch(authControllerProvider.future);
  if (viewer == null) {
    throw const LobbyViewDataException('Sign in to view this lobby.');
  }

  final snapshot = await ref.watch(currentGameProvider(gameId).future);

  final ids = <String>{
    for (final p in snapshot.players) p.mapPlayerId,
  }.toList();
  final profiles =
      await ref.read(playerRepositoryProvider).fetchProfilesByIds(ids);

  // ref.read so timer ticks do not re-run this future (fixes lobby flicker).
  final seconds = ref.read(gameSecondsRemainingProvider(gameId));

  return lobbyScenarioFromSession(
    session: snapshot,
    viewerPlayerId: viewer.playerId,
    profilesByPlayerId: profiles,
    tradingSecondsRemaining: seconds,
  );
}
