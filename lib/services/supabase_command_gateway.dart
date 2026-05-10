import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../data/enums/command_type.dart';
import '../data/models/command.dart';

/// Narrow adapter for the single Supabase operation that the command
/// repository needs: insert a row into `commands` and return its
/// generated `command_id`.
abstract class SupabaseCommandGateway {
  Future<String> insertCommandRow({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  });

  Future<List<Command>> fetchPendingCreateOrderCommands({
    required String gameId,
    required String playerId,
  });
}

class RealSupabaseCommandGateway implements SupabaseCommandGateway {
  RealSupabaseCommandGateway(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<String> insertCommandRow({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  }) async {
    final row = await _client.from('commands').insert(<String, dynamic>{
      'command_type': type.wireValue,
      'command_game_id': gameId,
      'player_id': playerId,
      'payload': payload,
      'command_status': 'pending',
      'attempt_count': 0,
    }).select('command_id').single();
    return row['command_id'] as String;
  }

  @override
  Future<List<Command>> fetchPendingCreateOrderCommands({
    required String gameId,
    required String playerId,
  }) async {
    final rows = await _client
        .from('commands')
        .select()
        .eq('command_game_id', gameId)
        .eq('player_id', playerId)
        .eq('command_type', CommandType.createOrder.wireValue)
        .or('command_status.eq.pending,command_status.eq.claimed,'
            'command_status.eq.failed')
        .order('command_created_at', ascending: false);

    final list = rows as List<dynamic>;
    return [
      for (final raw in list)
        Command.fromJson(Map<String, dynamic>.from(raw as Map)),
    ];
  }
}
