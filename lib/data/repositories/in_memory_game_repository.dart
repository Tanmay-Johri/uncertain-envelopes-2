import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../enums/end_condition.dart';
import '../enums/game_security.dart';
import '../enums/game_state.dart';
import '../enums/is_ranked.dart';
import '../enums/lobby_status.dart';
import '../models/game.dart';
import '../models/game_player.dart';
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

  /// Full GamePlayer rows per game, keyed by `games_players_row_id`.
  final Map<String, Map<String, GamePlayer>> _gamePlayers = {};

  void seedGame(Game game) {
    _games[game.gameId] = game;
  }

  void seedMembership(String gameId, String playerId) {
    _memberships.add('$gameId::$playerId');
  }

  void seedGamePlayer(GamePlayer player) {
    _gamePlayers
        .putIfAbsent(player.mapGameId, () => <String, GamePlayer>{})
        [player.gamesPlayersRowId] = player;
    _memberships.add('${player.mapGameId}::${player.mapPlayerId}');
  }

  void clear() {
    _games.clear();
    _memberships.clear();
    _gamePlayers.clear();
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

  static bool _isActiveForNameUniqueness(GameState state) {
    return state == GameState.created ||
        state == GameState.tradingStarted ||
        state == GameState.tradingEnded;
  }

  bool _activeGameNameTaken(String gameName) {
    return _games.values.any(
      (g) => g.gameName == gameName && _isActiveForNameUniqueness(g.gameState),
    );
  }

  @override
  Future<String> createGameAndReturnGameId({
    required String adminPlayerId,
    required String gameName,
    String? gameDescription,
    required GameSecurity gameSecurity,
    required IsRanked isRanked,
    required int gameMaxPlayers,
    required EndCondition endCondition,
    int? totalDecidedDurationSeconds,
  }) async {
    if (_activeGameNameTaken(gameName)) {
      throw const ActiveGameNameInUseException();
    }
    final commandId = await submitCreateGame(
      adminPlayerId: adminPlayerId,
      gameName: gameName,
      gameDescription: gameDescription,
      gameSecurity: gameSecurity,
      isRanked: isRanked,
      gameMaxPlayers: gameMaxPlayers,
      endCondition: endCondition,
      totalDecidedDurationSeconds: totalDecidedDurationSeconds,
    );
    final gameId = const Uuid().v4();
    final joiningCode = _uniqueJoiningCode(commandId);
    final now = DateTime.now().toUtc();
    _games[gameId] = Game(
      gameId: gameId,
      gameName: gameName,
      gameDescription: gameDescription,
      gameCreatedAt: now,
      gameSecurity: gameSecurity,
      isRanked: isRanked,
      gameMaxPlayers: gameMaxPlayers,
      joiningCode: joiningCode,
      endCondition: endCondition,
      totalDecidedDurationSeconds: totalDecidedDurationSeconds,
      endTimeDecided: null,
      startTime: null,
      endTimeActual: null,
      gameState: GameState.created,
      adminPlayerId: adminPlayerId,
      lastTradedPrice: null,
      envelopePrice: null,
      stateVersion: 0,
      updatedAt: now,
    );
    seedGamePlayer(
      GamePlayer(
        gamesPlayersRowId: const Uuid().v4(),
        mapGameId: gameId,
        mapPlayerId: adminPlayerId,
        lobbyStatus: LobbyStatus.playing,
        joinedAt: now,
        isAdmin: true,
        deltaCash: 0,
        deltaEnvelopes: 0,
        pnl: 0,
      ),
    );
    return gameId;
  }

  /// Deterministic 5-char code from [commandId]; retries if collision.
  String _uniqueJoiningCode(String commandId) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    for (var salt = 0; salt < 1000; salt++) {
      var h = salt * 1000003;
      for (final u in commandId.codeUnits) {
        h = 37 * h + u;
      }
      final buf = StringBuffer();
      for (var i = 0; i < 5; i++) {
        h = h * 1103515245 + 12345;
        buf.write(chars[h.abs() % chars.length]);
      }
      final code = buf.toString();
      if (!_games.values.any((g) => g.joiningCode == code)) {
        return code;
      }
    }
    return _joiningCodeFromSeed(const Uuid().v4());
  }

  String _joiningCodeFromSeed(String seed) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var h = 0;
    for (final u in seed.codeUnits) {
      h = 37 * h + u;
    }
    final buf = StringBuffer();
    for (var i = 0; i < 5; i++) {
      h = h * 1103515245 + 12345;
      buf.write(chars[h.abs() % chars.length]);
    }
    return buf.toString();
  }

  @override
  Future<Game?> fetchGame(String gameId) async => _games[gameId];

  @override
  Future<List<GamePlayer>> fetchGamePlayers(String gameId) async {
    final players = _gamePlayers[gameId]?.values.toList() ?? <GamePlayer>[];
    players.sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
    return players;
  }

  @override
  Future<Map<String, int>> fetchPlayerCountsByGameIds(
    List<String> gameIds,
  ) async {
    if (gameIds.isEmpty) return const {};
    final counts = <String, int>{for (final id in gameIds) id: 0};
    for (final key in _memberships) {
      final parts = key.split('::');
      if (parts.length != 2) continue;
      final gameId = parts[0];
      if (counts.containsKey(gameId)) {
        counts[gameId] = counts[gameId]! + 1;
      }
    }
    return counts;
  }

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
    if (game == null) throw GameNotFoundException.joiningCode(code);
    final cmdId = await _commands.submitJoinGame(
      gameId: game.gameId,
      playerId: playerId,
    );
    seedMembership(game.gameId, playerId);
    return JoinByCodeResult(gameId: game.gameId, commandId: cmdId);
  }
}
