import 'dart:async';

import '../data/enums/command_type.dart';
import '../data/models/command.dart';
import '../data/models/execution.dart';
import '../data/models/game.dart';
import '../data/models/game_player.dart';
import '../data/models/order.dart';
import 'realtime_event.dart';
import 'version_poller.dart';

/// The mutable state surface that a [GameRealtimeService] drives. A
/// production implementation bridges this to the Riverpod notifiers from
/// B8/B9; tests substitute a recording fake.
abstract class GameRealtimeTarget {
  /// The local authoritative `state_version`, or null if the session
  /// state has not yet loaded. Used for version-poll comparisons.
  int? get currentVersion;

  void applyGameUpdate(Game game);
  void applyPlayerUpsert(GamePlayer player);
  void applyPlayerRemoval(String playerId);
  void applyOrderUpsert(Order order);
  void applyOrderRemoval(String orderId);
  void applyExecutionInsert(Execution execution);

  /// INSERT/UPDATE on `commands` for `create_order` rows (B-GAP-1b).
  void applyPendingCreateOrderCommandUpsert(Command command);

  /// DELETE on `commands`, or explicit eviction by id.
  void applyPendingCreateOrderCommandRemoval(String commandId);

  /// Full-snapshot refresh from Postgres. Called on a version mismatch
  /// (the PRD "repair path") and on realtime disconnect->reconnect.
  Future<void> refreshAll();
}

/// Orchestrates the realtime + repair model described in the PRD §Realtime
/// + repair model.
///
/// Behaviour:
///   - Subscribes to row-level events from [RealtimeSubscriber] and applies
///     them to [target]. This is the fast path.
///   - On an interval of [pollInterval] (default 3s), asks [poller] for the
///     current authoritative version. If the remote version is higher than
///     [GameRealtimeTarget.currentVersion], triggers a full refresh. That
///     is the repair path for missed realtime events.
///   - [dispose] cancels both the subscription AND the poll timer.
class GameRealtimeService {
  GameRealtimeService({
    required this.gameId,
    required this.target,
    required this.subscriber,
    required this.poller,
    this.pollInterval = const Duration(seconds: 3),
  });

  final String gameId;
  final GameRealtimeTarget target;
  final RealtimeSubscriber subscriber;
  final VersionPoller poller;
  final Duration pollInterval;

  StreamSubscription<RealtimeEvent>? _eventSub;
  Timer? _pollTimer;
  bool _disposed = false;

  bool get isRunning => _eventSub != null;

  /// Must only be called once per instance. Throws StateError on reuse.
  Future<void> start() async {
    if (_disposed) {
      throw StateError('GameRealtimeService already disposed');
    }
    if (_eventSub != null) {
      throw StateError('GameRealtimeService already started');
    }
    _eventSub = subscriber.subscribeToGame(gameId).listen(
          _handle,
          onError: (Object _) {
            // Swallow stream errors — the service remains alive. The next
            // poll tick will detect any drift that was missed during the
            // transient outage.
          },
        );
    _pollTimer = Timer.periodic(pollInterval, (_) => pollOnce());
  }

  /// Exposed so tests can drive a poll tick deterministically without
  /// having to wait for the real timer.
  Future<void> pollOnce() async {
    if (_disposed) return;
    final remote = await poller.pollVersion(gameId);
    if (remote == null) return;
    final local = target.currentVersion;
    if (local == null) return;
    if (remote > local) {
      await target.refreshAll();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _eventSub?.cancel();
    _eventSub = null;
    try {
      await subscriber.disconnect();
    } catch (_) {
      // Disconnect failures shouldn't mask the dispose contract.
    }
  }

  void _handle(RealtimeEvent event) {
    switch (event.table) {
      case 'games':
        final row = event.newRow;
        if (row == null) return;
        final game = Game.fromJson(row);
        if (game.gameId != gameId) return;
        target.applyGameUpdate(game);
        break;
      case 'games_players':
        if (event.type == RealtimeEventType.delete) {
          final pid = event.oldRow?['map_player_id'] as String?;
          if (pid == null) return;
          final gid = event.oldRow?['map_game_id'] as String?;
          if (gid != null && gid != gameId) return;
          target.applyPlayerRemoval(pid);
        } else {
          final row = event.newRow;
          if (row == null) return;
          final gp = GamePlayer.fromJson(row);
          if (gp.mapGameId != gameId) return;
          target.applyPlayerUpsert(gp);
        }
        break;
      case 'orders':
        if (event.type == RealtimeEventType.delete) {
          final oid = event.oldRow?['order_id'] as String?;
          if (oid == null) return;
          final gid = event.oldRow?['game_id'] as String?;
          if (gid != null && gid != gameId) return;
          target.applyOrderRemoval(oid);
        } else {
          final row = event.newRow;
          if (row == null) return;
          final o = Order.fromJson(row);
          if (o.gameId != gameId) return;
          target.applyOrderUpsert(o);
        }
        break;
      case 'executions':
        if (event.type != RealtimeEventType.insert) return;
        final row = event.newRow;
        if (row == null) return;
        final ex = Execution.fromJson(row);
        if (ex.executionsGameId != gameId) return;
        target.applyExecutionInsert(ex);
        break;
      case 'commands':
        if (event.type == RealtimeEventType.delete) {
          final cid = event.oldRow?['command_id'] as String?;
          if (cid == null) return;
          final gid = event.oldRow?['command_game_id'] as String?;
          if (gid != null && gid != gameId) return;
          target.applyPendingCreateOrderCommandRemoval(cid);
          return;
        }
        final row = event.newRow;
        if (row == null) return;
        final cmd = Command.fromJson(row);
        if (cmd.commandGameId != gameId) return;
        if (cmd.commandType != CommandType.createOrder) return;
        target.applyPendingCreateOrderCommandUpsert(cmd);
        break;
    }
  }
}
