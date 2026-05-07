import '../models/execution.dart';
import 'execution_repository.dart';

class InMemoryExecutionRepository implements ExecutionRepository {
  final List<Execution> _executions = [];

  void seedExecution(Execution execution) {
    _executions.add(execution);
  }

  void seedExecutions(Iterable<Execution> executions) {
    _executions.addAll(executions);
  }

  void clear() => _executions.clear();

  @override
  Future<List<Execution>> fetchExecutionsForGame(String gameId) async {
    final filtered = _executions
        .where((e) => e.executionsGameId == gameId)
        .toList()
      ..sort((a, b) => a.executedAt.compareTo(b.executedAt));
    return filtered;
  }
}
