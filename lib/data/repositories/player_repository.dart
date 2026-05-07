import '../models/player.dart';

/// Aggregated performance stats for a player. Computed from completed
/// (`game_finalised`) ranked games only, per the PRD distinction between
/// ranked and casual games.
class PlayerStats {
  const PlayerStats({
    required this.gamesPlayed,
    required this.wins,
  }) : assert(gamesPlayed >= 0),
        assert(wins >= 0),
        assert(wins <= gamesPlayed);

  /// Total finalised ranked games the player was in.
  final int gamesPlayed;

  /// Finalised ranked games where the player had the highest PnL.
  final int wins;

  /// 0.0 when `gamesPlayed == 0` (no divide-by-zero).
  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  @override
  bool operator ==(Object other) =>
      other is PlayerStats &&
      other.gamesPlayed == gamesPlayed &&
      other.wins == wins;

  @override
  int get hashCode => Object.hash(gamesPlayed, wins);

  @override
  String toString() =>
      'PlayerStats(gamesPlayed: $gamesPlayed, wins: $wins, winRate: $winRate)';
}

/// Read + narrow write surface for the `players` table. Username edits are
/// the only non-auth mutation a player can make to their own row.
abstract class PlayerRepository {
  /// Returns the profile for [playerId], or null when it does not exist.
  Future<Player?> fetchProfile(String playerId);

  /// Updates a player's username. Normalises to lowercase before storing
  /// (PRD §players.username). Throws [UsernameAlreadyInUseException] when
  /// the new username is already taken (case-insensitive) and
  /// [PlayerNotFoundException] when [playerId] does not exist.
  Future<Player> updateUsername({
    required String playerId,
    required String newUsername,
  });

  /// Aggregated performance stats (finalised ranked games only).
  Future<PlayerStats> fetchPerformanceStats(String playerId);
}

sealed class PlayerRepositoryException implements Exception {
  const PlayerRepositoryException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType($message)';
}

class PlayerNotFoundException extends PlayerRepositoryException {
  const PlayerNotFoundException(String id)
      : super('No player with id "$id"');
}

class UsernameAlreadyInUseException extends PlayerRepositoryException {
  const UsernameAlreadyInUseException(String username)
      : super('Username "$username" is already taken');
}
