import '../../services/supabase_game_gateway.dart';
import '../enums/end_condition.dart';
import '../enums/game_security.dart';
import '../enums/is_ranked.dart';
import '../models/game.dart';
import 'command_repository.dart';
import 'game_repository.dart';

/// Production [GameRepository]. Delegates command submissions to the
/// injected [CommandRepository] (so all payload construction lives in
/// exactly one place) and delegates game-table reads to a
/// [SupabaseGameGateway].
class SupabaseGameRepository implements GameRepository {
  SupabaseGameRepository({
    required CommandRepository commandRepository,
    required SupabaseGameGateway gateway,
  })  : _commands = commandRepository,
        _gateway = gateway;

  final CommandRepository _commands;
  final SupabaseGameGateway _gateway;

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
  Future<Game?> fetchGame(String gameId) async {
    final row = await _gateway.fetchGameRow(gameId);
    return row == null ? null : Game.fromJson(row);
  }

  @override
  Future<List<Game>> fetchPublicGames() async {
    final rows = await _gateway.fetchPublicGameRows();
    return rows.map(Game.fromJson).toList();
  }

  @override
  Future<List<Game>> fetchJoinedGames(String playerId) async {
    final rows = await _gateway.fetchJoinedGameRows(playerId);
    return rows.map(Game.fromJson).toList();
  }

  @override
  Future<Game?> lookupGameByCode(String code) async {
    final row = await _gateway.lookupGameRowByCode(code.toUpperCase());
    return row == null ? null : Game.fromJson(row);
  }

  @override
  Future<JoinByCodeResult> joinByCode({
    required String code,
    required String playerId,
  }) async {
    final game = await lookupGameByCode(code);
    if (game == null) throw GameNotFoundException(code);
    final commandId = await _commands.submitJoinGame(
      gameId: game.gameId,
      playerId: playerId,
    );
    return JoinByCodeResult(gameId: game.gameId, commandId: commandId);
  }
}
