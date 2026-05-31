import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Narrow adapter for the `games` queries that the game repository needs.
/// All queries return raw row maps; the repository handles Game
/// deserialization so this layer stays trivial.
abstract class SupabaseGameGateway {
  Future<Map<String, dynamic>?> fetchGameRow(String gameId);
  Future<List<Map<String, dynamic>>> fetchGamePlayerRows(String gameId);

  /// Rows with at least `map_game_id` for every membership in [gameIds].
  Future<List<Map<String, dynamic>>> fetchPlayerCountRowsByGameIds(
    List<String> gameIds,
  );

  Future<List<Map<String, dynamic>>> fetchPublicGameRows();
  Future<List<Map<String, dynamic>>> fetchJoinedGameRows(String playerId);
  Future<Map<String, dynamic>?> lookupGameRowByCode(String code);

  /// Returns the `game_id` for [code] without triggering RLS on `games`.
  /// Used by `joinByCode` so non-members can resolve **private** games.
  /// Returns `null` when no active game has that code.
  Future<String?> lookupGameIdByJoiningCode(String code);

  /// Row for [createGameAndReturnGameId] polling: `command_status`,
  /// `command_game_id`.
  Future<Map<String, dynamic>?> fetchCommandStatusRow(String commandId);
}

class RealSupabaseGameGateway implements SupabaseGameGateway {
  RealSupabaseGameGateway(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchGameRow(String gameId) async {
    final row = await _client
        .from('games')
        .select()
        .eq('game_id', gameId)
        .maybeSingle();
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGamePlayerRows(String gameId) async {
    final rows = await _client
        .from('games_players')
        .select()
        .eq('map_game_id', gameId)
        .order('joined_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPlayerCountRowsByGameIds(
    List<String> gameIds,
  ) async {
    if (gameIds.isEmpty) return const [];
    final rows = await _client
        .from('games_players')
        .select('map_game_id')
        .inFilter('map_game_id', gameIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPublicGameRows() async {
    final rows = await _client
        .from('games')
        .select()
        .eq('game_security', 'public')
        .inFilter('game_state', ['created', 'trading_started'])
        .order('game_created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchJoinedGameRows(
    String playerId,
  ) async {
    final rows = await _client
        .from('games')
        .select('*, games_players!inner(map_player_id)')
        .eq('games_players.map_player_id', playerId)
        .order('game_created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<Map<String, dynamic>?> lookupGameRowByCode(String code) async {
    final row = await _client
        .from('games')
        .select()
        .eq('joining_code', code.toUpperCase())
        .maybeSingle();
    return row;
  }

  @override
  Future<String?> lookupGameIdByJoiningCode(String code) async {
    final result = await _client.rpc<dynamic>(
      'lookup_game_id_by_joining_code',
      params: {'p_code': code.toUpperCase()},
    );
    if (result == null) return null;
    if (result is String) return result.isEmpty ? null : result;
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchCommandStatusRow(String commandId) async {
    final row = await _client
        .from('commands')
        .select('command_status, command_game_id')
        .eq('command_id', commandId)
        .maybeSingle();
    return row;
  }
}
