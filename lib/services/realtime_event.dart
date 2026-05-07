/// Which kind of row-level change fired on the realtime channel.
enum RealtimeEventType { insert, update, delete }

/// A single realtime event from Supabase, normalised across tables.
///
/// `newRow` is populated for INSERT and UPDATE; `oldRow` is populated for
/// UPDATE and DELETE. The repository/service layer is responsible for
/// extracting the right row to decode.
class RealtimeEvent {
  const RealtimeEvent({
    required this.type,
    required this.table,
    required this.newRow,
    required this.oldRow,
  });

  final RealtimeEventType type;
  final String table;
  final Map<String, dynamic>? newRow;
  final Map<String, dynamic>? oldRow;

  @override
  String toString() =>
      'RealtimeEvent($type $table, new=${newRow != null}, old=${oldRow != null})';
}

/// Narrow seam for subscribing to realtime events for a given game.
/// Production impl wraps Supabase Realtime; tests inject a
/// StreamController-backed fake.
abstract class RealtimeSubscriber {
  /// Returns a single merged stream of [RealtimeEvent]s across every
  /// table relevant to [gameId] (games, games_players, orders,
  /// executions). The stream must remain open until [disconnect] is
  /// called.
  Stream<RealtimeEvent> subscribeToGame(String gameId);

  /// Detach from any underlying channels. Idempotent.
  Future<void> disconnect();
}
