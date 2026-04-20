import '../enums/end_condition.dart';
import '../enums/game_security.dart';
import '../enums/is_ranked.dart';
import '../models/game.dart';

/// Read-side + command-submission surface for games. Command submissions
/// for game-level actions are delegated to [CommandRepository]; this
/// repository owns lookups against the `games` table and the
/// lookup-by-code flow.
abstract class GameRepository {
  /// Submits a `create_game` command. Returns the command id (the caller
  /// polls / watches for processing to complete, then loads the new game
  /// via realtime or the game list).
  Future<String> submitCreateGame({
    required String adminPlayerId,
    required String gameName,
    String? gameDescription,
    required GameSecurity gameSecurity,
    required IsRanked isRanked,
    required int gameMaxPlayers,
    required EndCondition endCondition,
    int? totalDecidedDurationSeconds,
  });

  /// Fetches the full game row by id, or null when it does not exist.
  Future<Game?> fetchGame(String gameId);

  /// Public-and-joinable games. Excludes discarded / finalised / ended
  /// games because the home screen only surfaces ones a player can enter.
  Future<List<Game>> fetchPublicGames();

  /// Every game the player has a `games_players` row in, regardless of
  /// state (ongoing OR historical).
  Future<List<Game>> fetchJoinedGames(String playerId);

  /// Looks up a game by its joining code regardless of state. Returns
  /// null if no such game exists.
  Future<Game?> lookupGameByCode(String code);

  /// Convenience: looks up a game by code and submits a `join_game`
  /// command for [playerId] in one call. Returns the resolved
  /// `game_id`. Throws [GameNotFoundException] if the code does not
  /// match any game.
  Future<JoinByCodeResult> joinByCode({
    required String code,
    required String playerId,
  });
}

class JoinByCodeResult {
  const JoinByCodeResult({required this.gameId, required this.commandId});
  final String gameId;
  final String commandId;
}

sealed class GameRepositoryException implements Exception {
  const GameRepositoryException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType($message)';
}

class GameNotFoundException extends GameRepositoryException {
  const GameNotFoundException(String code)
      : super('No game found with joining code "$code"');
}
