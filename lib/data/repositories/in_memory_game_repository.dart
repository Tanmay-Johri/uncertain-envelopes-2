import 'package:collection/collection.dart';

import '../enums/end_condition.dart';
import '../enums/game_security.dart';
import '../enums/game_state.dart';
import '../enums/is_ranked.dart';
import '../models/game.dart';
import 'command_repository.dart';
import 'game_repository.dart';

/// Deterministic in-memory [GameRepository] for tests. Seed games with
/// [seedGame] and membership with [seedMembership]; read methods honour
/// what has been seeded. Command submissions are forwarded to the
/// injected [CommandRepository] (typically an in-memory fake) so tests
/// can still inspect the emitted command payloads.
class InMemoryGameRepository implements GameRepository {
  InMemoryGameRepository({required CommandRepository commandRepository})
      : _commands = commandRepository;

  final CommandRepository _commands;
  final Map<String, Game> _games = {};

  /// Membership encoded as "gameId::playerId" so the composite key cannot
  /// collide with either id containing a colon.
  final Set<String> _memberships = {};

  void seedGame(Game game) {
    _games[game.gameId] = game;
  }

  void seedMembership(String gameId, String playerId) {
    _memberships.add('$gameId::$playerId');
  }

  void clear() {
    _games.clear();
    _memberships.clear();
  }

  @override
  Future<String> submitCreateGame({
    required String adminPlayerId,
    required String gameName,
    String? gameDescription,
    required GameSecurity gameSecurity,
    required IsRanked isRanked,
    required int gameMaxPlayers,
    required EndCondition endCondition,
    int? totalDecidedDurationSeconds,
  }) {
    return _commands.submitCreateGame(
      adminPlayerId: adminPlayerId,
      gameName: gameName,
      gameDescription: gameDescription,
      gameSecurity: gameSecurity,
      isRanked: isRanked,
      gameMaxPlayers: gameMaxPlayers,
      endCondition: endCondition,
      totalDecidedDurationSeconds: totalDecidedDurationSeconds,
    );
  }

  @override
  Future<Game?> fetchGame(String gameId) async => _games[gameId];

  @override
  Future<List<Game>> fetchPublicGames() async {
    return _games.values
        .where(
          (g) =>
              g.gameSecurity == GameSecurity.public &&
              (g.gameState == GameState.created ||
                  g.gameState == GameState.tradingStarted),
        )
        .toList();
  }

  @override
  Future<List<Game>> fetchJoinedGames(String playerId) async {
    final joinedIds = _memberships
        .where((m) => m.endsWith('::$playerId'))
        .map((m) => m.split('::').first);
    return joinedIds
        .map((id) => _games[id])
        .whereType<Game>()
        .toList();
  }

  @override
  Future<Game?> lookupGameByCode(String code) async {
    final up = code.toUpperCase();
    return _games.values.firstWhereOrNull((g) => g.joiningCode == up);
  }

  @override
  Future<JoinByCodeResult> joinByCode({
    required String code,
    required String playerId,
  }) async {
    final game = await lookupGameByCode(code);
    if (game == null) throw GameNotFoundException(code);
    final cmdId = await _commands.submitJoinGame(
      gameId: game.gameId,
      playerId: playerId,
    );
    seedMembership(game.gameId, playerId);
    return JoinByCodeResult(gameId: game.gameId, commandId: cmdId);
  }
}
