import '../enums/end_condition.dart';
import '../enums/game_security.dart';
import '../enums/is_ranked.dart';
import '../models/game.dart';
import '../models/game_player.dart';

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

  /// Submits `create_game` and returns the new `game_id` once it exists.
  ///
  /// In-memory: applies the game row immediately after the command insert.
  /// Supabase: polls `commands` until `processed` with `command_game_id` set
  /// (or throws on rejection / timeout).
  Future<String> createGameAndReturnGameId({
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

  /// Every `games_players` row for [gameId]. Empty list if the game has
  /// no members (e.g. immediately after creation, before the admin row
  /// is inserted).
  Future<List<GamePlayer>> fetchGamePlayers(String gameId);

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
  /// Five-letter code lookup failed ([joinByCode], home screen).
  const GameNotFoundException.joiningCode(String code)
      : super('No game found with joining code "$code"');

  /// [fetchGame] returned null — wrong code messaging would confuse users
  /// when the id is a UUID (RLS race after join, or game deleted).
  const GameNotFoundException.gameUnavailable(String gameId)
      : super(
          'Game is not available yet or no longer exists.',
        );
}

/// Another non-terminal game already uses this [game_name].
class ActiveGameNameInUseException extends GameRepositoryException {
  const ActiveGameNameInUseException()
      : super('A game with this name is already active.');
}

class CreateGameCommandFailedException extends GameRepositoryException {
  const CreateGameCommandFailedException(super.message);
}

class CreateGameTimeoutException extends GameRepositoryException {
  const CreateGameTimeoutException(super.message);
}
