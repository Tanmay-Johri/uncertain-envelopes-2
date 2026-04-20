import 'package:collection/collection.dart';

import 'game.dart';
import 'game_player.dart';

/// The portion of a live game that drives the lobby screen, the header on
/// the trading screen, and the countdown timer. Orders and executions live
/// in their own providers (B9) because they churn far more frequently and
/// should not force the lobby UI to rebuild on every order book change.
class GameSessionState {
  GameSessionState({
    required this.game,
    required List<GamePlayer> players,
  }) : players = List.unmodifiable(players);

  final Game game;
  final List<GamePlayer> players;

  GameSessionState copyWith({
    Game? game,
    List<GamePlayer>? players,
  }) {
    return GameSessionState(
      game: game ?? this.game,
      players: players ?? this.players,
    );
  }

  /// Upsert [player] by `games_players_row_id` (stable identity).
  GameSessionState upsertPlayer(GamePlayer player) {
    final updated = [
      for (final p in players)
        if (p.gamesPlayersRowId == player.gamesPlayersRowId) player else p,
    ];
    final existed =
        players.any((p) => p.gamesPlayersRowId == player.gamesPlayersRowId);
    if (!existed) updated.add(player);
    return copyWith(players: updated);
  }

  /// Remove by `map_player_id` (not row id) because leave/kick events give
  /// us the player id, not the membership row id.
  GameSessionState removePlayerByPlayerId(String playerId) {
    return copyWith(
      players: players.where((p) => p.mapPlayerId != playerId).toList(),
    );
  }

  GamePlayer? playerById(String playerId) =>
      players.firstWhereOrNull((p) => p.mapPlayerId == playerId);

  bool isAdmin(String playerId) =>
      players.any((p) => p.mapPlayerId == playerId && p.isAdmin);

  int get playerCount => players.length;

  @override
  bool operator ==(Object other) {
    if (other is! GameSessionState) return false;
    if (other.game != game) return false;
    return const ListEquality<GamePlayer>().equals(other.players, players);
  }

  @override
  int get hashCode => Object.hash(
        game,
        const ListEquality<GamePlayer>().hash(players),
      );

  @override
  String toString() =>
      'GameSessionState(game=${game.gameId}, players=${players.length})';
}
