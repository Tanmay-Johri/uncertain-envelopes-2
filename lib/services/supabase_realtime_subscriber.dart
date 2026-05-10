import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'realtime_event.dart';

/// Maps a Supabase postgres change payload to our neutral [RealtimeEvent].
///
/// Exposed for unit tests (Phase 2A.3 contract).
@visibleForTesting
RealtimeEvent mapPostgresPayloadToRealtimeEvent(PostgresChangePayload payload) {
  final RealtimeEventType type;
  switch (payload.eventType) {
    case PostgresChangeEvent.insert:
      type = RealtimeEventType.insert;
      break;
    case PostgresChangeEvent.update:
      type = RealtimeEventType.update;
      break;
    case PostgresChangeEvent.delete:
      type = RealtimeEventType.delete;
      break;
    case PostgresChangeEvent.all:
      throw ArgumentError(
        'postgres payload eventType must be INSERT/UPDATE/DELETE',
      );
  }

  Map<String, dynamic>? rowOrNull(Map<String, dynamic> m) =>
      m.isEmpty ? null : Map<String, dynamic>.from(m);

  return RealtimeEvent(
    type: type,
    table: payload.table,
    newRow: rowOrNull(payload.newRecord),
    oldRow: rowOrNull(payload.oldRecord),
  );
}

/// [RealtimeSubscriber] backed by Supabase Realtime postgres changes.
///
/// One channel per active session; filters match Stream A realtime contract
/// (`map_game_id` on `games_players`, `executions_game_id` on `executions`).
class SupabaseRealtimeSubscriber implements RealtimeSubscriber {
  SupabaseRealtimeSubscriber(
    this._client, {
    Duration reconnectDelay = const Duration(milliseconds: 50),
  }) : _reconnectDelay = reconnectDelay;

  final SupabaseClient _client;
  final Duration _reconnectDelay;

  RealtimeChannel? _channel;
  StreamController<RealtimeEvent>? _controller;
  String? _gameId;
  Timer? _reconnectTimer;
  bool _acceptEvents = false;

  /// Incremented each time a terminal subscribe status schedules a reconnect.
  int reconnectSchedules = 0;

  void _safeAdd(RealtimeEvent e) {
    final c = _controller;
    if (!_acceptEvents || c == null || c.isClosed) return;
    c.add(e);
  }

  void _scheduleReconnect() {
    if (!_acceptEvents || _gameId == null) return;
    reconnectSchedules++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (!_acceptEvents || _gameId == null) return;
      unawaited(_replaceChannel(_gameId!));
    });
  }

  Future<void> _unsubscribeChannel() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final ch = _channel;
    _channel = null;
    if (ch != null) {
      try {
        await ch.unsubscribe();
      } catch (_) {}
    }
  }

  Future<void> _replaceChannel(String gameId) async {
    await _unsubscribeChannel();
    if (!_acceptEvents || _controller == null || _controller!.isClosed) {
      return;
    }

    final channel = _client.channel('ue-game-$gameId');
    _channel = channel;

    void emit(PostgresChangePayload p) {
      try {
        _safeAdd(mapPostgresPayloadToRealtimeEvent(p));
      } catch (_) {}
    }

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'games',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'game_id',
          value: gameId,
        ),
        callback: emit,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'games_players',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'map_game_id',
          value: gameId,
        ),
        callback: emit,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'game_id',
          value: gameId,
        ),
        callback: emit,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'executions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'executions_game_id',
          value: gameId,
        ),
        callback: emit,
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'commands',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'command_game_id',
          value: gameId,
        ),
        callback: emit,
      )
      ..subscribe((status, err) {
        if (!_acceptEvents) return;
        if (status == RealtimeSubscribeStatus.subscribed) {
          return;
        }
        if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.timedOut ||
            status == RealtimeSubscribeStatus.closed) {
          _scheduleReconnect();
        }
      });
  }

  @override
  Stream<RealtimeEvent> subscribeToGame(String gameId) {
    _acceptEvents = true;
    _gameId = gameId;
    _controller?.close();
    _controller = StreamController<RealtimeEvent>.broadcast();
    unawaited(_replaceChannel(gameId));
    return _controller!.stream;
  }

  @override
  Future<void> disconnect() async {
    _acceptEvents = false;
    _gameId = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _unsubscribeChannel();
    await _controller?.close();
    _controller = null;
  }
}
