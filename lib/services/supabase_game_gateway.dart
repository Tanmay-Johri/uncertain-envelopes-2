import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Narrow adapter for the `games` queries that the game repository needs.
/// All queries return raw row maps; the repository handles Game
/// deserialization so this layer stays trivial.
abstract class SupabaseGameGateway {
  Future<Map<String, dynamic>?> fetchGameRow(String gameId);
  Future<List<Map<String, dynamic>>> fetchGamePlayerRows(String gameId);
  Future<List<Map<String, dynamic>>> fetchPublicGameRows();
  Future<List<Map<String, dynamic>>> fetchJoinedGameRows(String playerId);
  Future<Map<String, dynamic>?> lookupGameRowByCode(String code);

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
  Future<Map<String, dynamic>?> fetchCommandStatusRow(String commandId) async {
    final row = await _client
        .from('commands')
        .select('command_status, command_game_id')
        .eq('command_id', commandId)
        .maybeSingle();
    return row;
  }
}
