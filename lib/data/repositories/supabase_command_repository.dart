import '../../services/supabase_command_gateway.dart';
import '../enums/command_type.dart';
import 'command_repository.dart';

/// Production [CommandRepository] backed by Supabase Postgres. All payload
/// construction and validation lives in [BaseCommandRepository]; this
/// class only delegates the raw insert to the gateway.
class SupabaseCommandRepository extends BaseCommandRepository {
  SupabaseCommandRepository(this._gateway);

  final SupabaseCommandGateway _gateway;

  @override
  Future<String> doInsert({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  }) {
    return _gateway.insertCommandRow(
      type: type,
      gameId: gameId,
      playerId: playerId,
      payload: payload,
    );
  }
}
