import '../models/execution.dart';

/// Read-only access to the `executions` table. Executions are produced by
/// the matching engine (Stream A) and are never written client-side.
abstract class ExecutionRepository {
  /// Every execution for [gameId], sorted by `executed_at` ascending so
  /// the consumer can render a chronological price chart without
  /// re-sorting.
  Future<List<Execution>> fetchExecutionsForGame(String gameId);
}
