import '../../services/supabase_execution_gateway.dart';
import '../models/execution.dart';
import 'execution_repository.dart';

class SupabaseExecutionRepository implements ExecutionRepository {
  SupabaseExecutionRepository(this._gateway);
  final SupabaseExecutionGateway _gateway;

  @override
  Future<List<Execution>> fetchExecutionsForGame(String gameId) async {
    final rows = await _gateway.fetchExecutionRows(gameId);
    return rows.map(Execution.fromJson).toList();
  }
}
