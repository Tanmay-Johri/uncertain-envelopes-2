import 'package:supabase_flutter/supabase_flutter.dart' as sb;

abstract class SupabaseExecutionGateway {
  Future<List<Map<String, dynamic>>> fetchExecutionRows(String gameId);
}

class RealSupabaseExecutionGateway implements SupabaseExecutionGateway {
  RealSupabaseExecutionGateway(this._client);
  final sb.SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchExecutionRows(
    String gameId,
  ) async {
    final rows = await _client
        .from('executions')
        .select()
        .eq('executions_game_id', gameId)
        .order('executed_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }
}
