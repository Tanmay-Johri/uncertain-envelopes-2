import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uncertain_envelopes_2/services/realtime_event.dart';
import 'package:uncertain_envelopes_2/services/supabase_realtime_subscriber.dart';

class _FakeChannel extends Fake implements RealtimeChannel {
  _FakeChannel(this.id);
  final int id;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload payload) callback,
  }) =>
      this;

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus status, Object? error)? callback,
    Duration? timeout,
  ]) {
    scheduleMicrotask(() {
      if (id == 1) {
        callback?.call(RealtimeSubscribeStatus.channelError, Exception('boom'));
      } else {
        callback?.call(RealtimeSubscribeStatus.subscribed, null);
      }
    });
    return this;
  }

  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';
}

class _MockClient extends Mock implements SupabaseClient {}

void main() {
  group('mapPostgresPayloadToRealtimeEvent', () {
    test('games UPDATE maps to update with newRow only', () {
      final p = PostgresChangePayload(
        schema: 'public',
        table: 'games',
        commitTimestamp: DateTime.utc(2026, 1, 1),
        eventType: PostgresChangeEvent.update,
        newRecord: {'game_id': 'g1', 'state_version': 2},
        oldRecord: const {},
        errors: null,
      );
      final e = mapPostgresPayloadToRealtimeEvent(p);
      expect(e.type, RealtimeEventType.update);
      expect(e.table, 'games');
      expect(e.newRow, {'game_id': 'g1', 'state_version': 2});
      expect(e.oldRow, isNull);
    });

    test('games_players DELETE carries map_player_id and map_game_id in oldRow',
        () {
      final p = PostgresChangePayload(
        schema: 'public',
        table: 'games_players',
        commitTimestamp: DateTime.utc(2026, 1, 1),
        eventType: PostgresChangeEvent.delete,
        newRecord: const {},
        oldRecord: {
          'map_player_id': 'p-leave',
          'map_game_id': 'g1',
          'games_players_row_id': 'r1',
        },
        errors: null,
      );
      final e = mapPostgresPayloadToRealtimeEvent(p);
      expect(e.type, RealtimeEventType.delete);
      expect(e.table, 'games_players');
      expect(e.newRow, isNull);
      expect(e.oldRow!['map_player_id'], 'p-leave');
      expect(e.oldRow!['map_game_id'], 'g1');
    });

    test('orders DELETE carries order_id and game_id in oldRow', () {
      final p = PostgresChangePayload(
        schema: 'public',
        table: 'orders',
        commitTimestamp: DateTime.utc(2026, 1, 1),
        eventType: PostgresChangeEvent.delete,
        newRecord: const {},
        oldRecord: {'order_id': 'o99', 'game_id': 'g1'},
        errors: null,
      );
      final e = mapPostgresPayloadToRealtimeEvent(p);
      expect(e.type, RealtimeEventType.delete);
      expect(e.oldRow!['order_id'], 'o99');
      expect(e.oldRow!['game_id'], 'g1');
    });

    test('orders INSERT maps to insert', () {
      final p = PostgresChangePayload(
        schema: 'public',
        table: 'orders',
        commitTimestamp: DateTime.utc(2026, 1, 1),
        eventType: PostgresChangeEvent.insert,
        newRecord: {'order_id': 'o1', 'game_id': 'g1'},
        oldRecord: const {},
        errors: null,
      );
      final e = mapPostgresPayloadToRealtimeEvent(p);
      expect(e.type, RealtimeEventType.insert);
      expect(e.newRow!['order_id'], 'o1');
    });

    test('executions INSERT maps to insert with newRow', () {
      final p = PostgresChangePayload(
        schema: 'public',
        table: 'executions',
        commitTimestamp: DateTime.utc(2026, 1, 1),
        eventType: PostgresChangeEvent.insert,
        newRecord: {'executions_id': 'e1', 'executions_game_id': 'g1'},
        oldRecord: const {},
        errors: null,
      );
      final e = mapPostgresPayloadToRealtimeEvent(p);
      expect(e.type, RealtimeEventType.insert);
      expect(e.table, 'executions');
      expect(e.newRow!['executions_game_id'], 'g1');
    });

    test('games_players UPDATE has both rows when server sends them', () {
      final p = PostgresChangePayload(
        schema: 'public',
        table: 'games_players',
        commitTimestamp: DateTime.utc(2026, 1, 1),
        eventType: PostgresChangeEvent.update,
        newRecord: {'map_player_id': 'p1', 'delta_cash': 10.0},
        oldRecord: {'map_player_id': 'p1', 'delta_cash': 0.0},
        errors: null,
      );
      final e = mapPostgresPayloadToRealtimeEvent(p);
      expect(e.type, RealtimeEventType.update);
      expect(e.newRow!['delta_cash'], 10.0);
      expect(e.oldRow!['delta_cash'], 0.0);
    });

    test('throws on impossible ALL payload eventType', () {
      final p = PostgresChangePayload(
        schema: 'public',
        table: 'orders',
        commitTimestamp: DateTime.utc(2026, 1, 1),
        eventType: PostgresChangeEvent.all,
        newRecord: const {},
        oldRecord: const {},
        errors: null,
      );
      expect(() => mapPostgresPayloadToRealtimeEvent(p), throwsArgumentError);
    });
  });

  group('SupabaseRealtimeSubscriber reconnect', () {
    test('channelError schedules at least one reconnect', () async {
      final client = _MockClient();
      var nextId = 0;
      when(() => client.channel(any())).thenAnswer((_) {
        nextId++;
        return _FakeChannel(nextId);
      });

      final sub = SupabaseRealtimeSubscriber(
        client,
        reconnectDelay: const Duration(milliseconds: 5),
      );
      final listen = sub.subscribeToGame('g-reconnect').listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(sub.reconnectSchedules, greaterThanOrEqualTo(1));
      expect(nextId, greaterThanOrEqualTo(2));
      await listen.cancel();
      await sub.disconnect();
    });
  });
}
