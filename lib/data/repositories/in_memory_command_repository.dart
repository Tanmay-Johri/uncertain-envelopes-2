import '../enums/command_type.dart';
import 'command_repository.dart';

/// In-memory [CommandRepository] used by tests for downstream layers
/// (GameRepository, providers). Every [insertCommand] call is recorded so
/// the test can assert on payload contents and ordering.
class InMemoryCommandRepository extends BaseCommandRepository {
  InMemoryCommandRepository({int startId = 1}) : _nextId = startId;

  final List<RecordedCommand> inserts = [];
  int _nextId;

  @override
  Future<String> doInsert({
    required CommandType type,
    required String? gameId,
    required String? playerId,
    required Map<String, dynamic> payload,
  }) async {
    final id = 'cmd-${_nextId++}';
    inserts.add(
      RecordedCommand(
        commandId: id,
        type: type,
        gameId: gameId,
        playerId: playerId,
        payload: Map<String, dynamic>.unmodifiable(payload),
      ),
    );
    return id;
  }

  /// Convenience for test assertions.
  RecordedCommand? lastOfType(CommandType type) {
    for (final c in inserts.reversed) {
      if (c.type == type) return c;
    }
    return null;
  }
}

class RecordedCommand {
  const RecordedCommand({
    required this.commandId,
    required this.type,
    required this.gameId,
    required this.playerId,
    required this.payload,
  });

  final String commandId;
  final CommandType type;
  final String? gameId;
  final String? playerId;
  final Map<String, dynamic> payload;

  @override
  String toString() =>
      'RecordedCommand($commandId, ${type.wireValue}, game=$gameId, player=$playerId, payload=$payload)';
}
