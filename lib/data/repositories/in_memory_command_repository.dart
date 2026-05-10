import '../enums/command_status.dart';
import '../enums/command_type.dart';
import '../models/command.dart';
import 'command_repository.dart';

/// In-memory [CommandRepository] used by tests for downstream layers
/// (GameRepository, providers). Every [insertCommand] call is recorded so
/// the test can assert on payload contents and ordering.
class InMemoryCommandRepository extends BaseCommandRepository {
  InMemoryCommandRepository({int startId = 1}) : _nextId = startId;

  final List<RecordedCommand> inserts = [];
  final List<Command> _trackedCommands = [];
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
    if (type == CommandType.createOrder &&
        gameId != null &&
        playerId != null) {
      _trackedCommands.add(
        Command(
          commandId: id,
          commandGameId: gameId,
          commandCreatedAt: DateTime.utc(2026, 1, 1, 12, 0, 0, _trackedCommands.length),
          playerId: playerId,
          commandType: type,
          payload: Map<String, dynamic>.from(payload),
          commandStatus: CommandStatus.pending,
          claimToken: null,
          claimedAt: null,
          attemptCount: 0,
          finishedAt: null,
        ),
      );
    }
    return id;
  }

  @override
  Future<List<Command>> fetchPendingCreateOrderCommands({
    required String gameId,
    required String playerId,
  }) async {
    return [
      for (final c in _trackedCommands)
        if (c.commandType == CommandType.createOrder &&
            c.commandGameId == gameId &&
            c.playerId == playerId &&
            !c.commandStatus.isTerminal)
          c,
    ];
  }

  /// Moves a tracked `create_order` command to a new status (tests only).
  void setCreateOrderCommandStatusForTest(
    String commandId,
    CommandStatus status,
  ) {
    final i = _trackedCommands.indexWhere((c) => c.commandId == commandId);
    if (i < 0) return;
    _trackedCommands[i] = _trackedCommands[i].copyWith(commandStatus: status);
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
