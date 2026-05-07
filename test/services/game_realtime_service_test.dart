import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/lobby_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/models/execution.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/game_player.dart';
import 'package:uncertain_envelopes_2/data/models/order.dart';
import 'package:uncertain_envelopes_2/services/game_realtime_service.dart';
import 'package:uncertain_envelopes_2/services/realtime_event.dart';
import 'package:uncertain_envelopes_2/services/version_poller.dart';

Game _game({int version = 1, String id = 'g-1'}) => Game(
      gameId: id,
      gameName: 'G',
      gameCreatedAt: DateTime.utc(2026, 1, 1, 10),
      gameSecurity: GameSecurity.public,
      isRanked: IsRanked.casual,
      gameMaxPlayers: 10,
      joiningCode: 'AB12C',
      endCondition: EndCondition.endless,
      gameState: GameState.created,
      adminPlayerId: 'p-admin',
      stateVersion: version,
      updatedAt: DateTime.utc(2026, 1, 1, 10),
    );

Map<String, dynamic> _gameRow({int version = 1, String id = 'g-1'}) =>
    _game(version: version, id: id).toJson();

Map<String, dynamic> _playerRow({
  String rowId = 'r-1',
  String playerId = 'p-1',
  String gameId = 'g-1',
  bool admin = false,
}) =>
    GamePlayer(
      gamesPlayersRowId: rowId,
      mapGameId: gameId,
      mapPlayerId: playerId,
      lobbyStatus: LobbyStatus.playing,
      joinedAt: DateTime.utc(2026, 1, 1, 10),
      isAdmin: admin,
      deltaCash: 0,
      deltaEnvelopes: 0,
      pnl: 0,
    ).toJson();

Map<String, dynamic> _orderRow({
  String id = 'o-1',
  String gameId = 'g-1',
  String playerId = 'p-1',
}) =>
    Order(
      orderId: id,
      createdByPlayerId: playerId,
      gameId: gameId,
      type: OrderType.limitBuy,
      quantityInitial: 5,
      quantityCurrent: 5,
      pricePerStock: 100,
      status: OrderStatus.orderResting,
      orderCreatedAt: DateTime.utc(2026, 1, 1, 10),
      orderUpdatedAt: DateTime.utc(2026, 1, 1, 10),
    ).toJson();

Map<String, dynamic> _execRow({
  String id = 'e-1',
  String gameId = 'g-1',
}) =>
    Execution(
      executionsId: id,
      executionsGameId: gameId,
      buyOrderId: 'b',
      sellOrderId: 's',
      quantity: 1,
      executionPrice: 100,
      executedAt: DateTime.utc(2026, 1, 1, 10),
    ).toJson();

void main() {
  group('GameRealtimeService event routing', () {
    late _FakeSubscriber subscriber;
    late _FakeTarget target;
    late _FakePoller poller;
    late GameRealtimeService service;

    setUp(() async {
      subscriber = _FakeSubscriber();
      target = _FakeTarget(version: 1);
      poller = _FakePoller(version: 1);
      service = GameRealtimeService(
        gameId: 'g-1',
        target: target,
        subscriber: subscriber,
        poller: poller,
        pollInterval: const Duration(hours: 1),
      );
      await service.start();
    });

    tearDown(() async {
      await service.dispose();
    });

    test('games INSERT/UPDATE -> applyGameUpdate with decoded Game',
        () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.update,
        table: 'games',
        newRow: _gameRow(version: 2),
        oldRow: _gameRow(version: 1),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.gameUpdates.single.stateVersion, 2);
    });

    test('games event for a different gameId is ignored', () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.update,
        table: 'games',
        newRow: _gameRow(id: 'g-OTHER'),
        oldRow: null,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.gameUpdates, isEmpty);
    });

    test('games_players INSERT -> applyPlayerUpsert', () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.insert,
        table: 'games_players',
        newRow: _playerRow(rowId: 'r-1', playerId: 'p-1'),
        oldRow: null,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.playerUpserts.single.mapPlayerId, 'p-1');
    });

    test('games_players DELETE -> applyPlayerRemoval using oldRow',
        () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.delete,
        table: 'games_players',
        newRow: null,
        oldRow: _playerRow(rowId: 'r-1', playerId: 'p-1'),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.playerRemovals.single, 'p-1');
    });

    test('games_players event for another game is ignored', () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.insert,
        table: 'games_players',
        newRow: _playerRow(gameId: 'g-other'),
        oldRow: null,
      ));
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.delete,
        table: 'games_players',
        newRow: null,
        oldRow: _playerRow(gameId: 'g-other'),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.playerUpserts, isEmpty);
      expect(target.playerRemovals, isEmpty);
    });

    test('orders INSERT/UPDATE -> applyOrderUpsert; DELETE -> removal',
        () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.insert,
        table: 'orders',
        newRow: _orderRow(id: 'o-1'),
        oldRow: null,
      ));
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.delete,
        table: 'orders',
        newRow: null,
        oldRow: _orderRow(id: 'o-1'),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.orderUpserts.single.orderId, 'o-1');
      expect(target.orderRemovals.single, 'o-1');
    });

    test('executions non-insert events ignored (table is append-only)',
        () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.update,
        table: 'executions',
        newRow: _execRow(),
        oldRow: _execRow(),
      ));
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.delete,
        table: 'executions',
        newRow: null,
        oldRow: _execRow(),
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.executionInserts, isEmpty);
    });

    test('executions INSERT is forwarded', () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.insert,
        table: 'executions',
        newRow: _execRow(id: 'e-1'),
        oldRow: null,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.executionInserts.single.executionsId, 'e-1');
    });

    test('unknown tables are silently ignored', () async {
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.insert,
        table: 'unrelated_table',
        newRow: {'whatever': 1},
        oldRow: null,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.everythingSeen, 0);
    });

    test('stream errors do not kill the service', () async {
      subscriber.emitError(StateError('boom'));
      subscriber.emit(RealtimeEvent(
        type: RealtimeEventType.insert,
        table: 'games_players',
        newRow: _playerRow(rowId: 'r-1', playerId: 'p-1'),
        oldRow: null,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(target.playerUpserts.single.mapPlayerId, 'p-1');
      expect(service.isRunning, true);
    });
  });

  group('GameRealtimeService version repair', () {
    test('pollOnce with equal versions does not refresh', () async {
      final subscriber = _FakeSubscriber();
      final target = _FakeTarget(version: 5);
      final poller = _FakePoller(version: 5);
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: target,
        subscriber: subscriber,
        poller: poller,
      );
      await svc.start();
      await svc.pollOnce();
      expect(target.refreshCount, 0);
      await svc.dispose();
    });

    test('pollOnce with higher remote version triggers a refresh',
        () async {
      final subscriber = _FakeSubscriber();
      final target = _FakeTarget(version: 5);
      final poller = _FakePoller(version: 9);
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: target,
        subscriber: subscriber,
        poller: poller,
      );
      await svc.start();
      await svc.pollOnce();
      expect(target.refreshCount, 1);
      await svc.dispose();
    });

    test('pollOnce with null remote (both sources down) does not refresh',
        () async {
      final subscriber = _FakeSubscriber();
      final target = _FakeTarget(version: 5);
      final poller = _FakePoller(version: null);
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: target,
        subscriber: subscriber,
        poller: poller,
      );
      await svc.start();
      await svc.pollOnce();
      expect(target.refreshCount, 0);
      await svc.dispose();
    });

    test('pollOnce skipped before state loads (currentVersion null)',
        () async {
      final subscriber = _FakeSubscriber();
      final target = _FakeTarget(version: null);
      final poller = _FakePoller(version: 10);
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: target,
        subscriber: subscriber,
        poller: poller,
      );
      await svc.start();
      await svc.pollOnce();
      expect(target.refreshCount, 0);
      await svc.dispose();
    });
  });

  group('GameRealtimeService lifecycle', () {
    test('dispose cancels subscription and disconnects subscriber',
        () async {
      final subscriber = _FakeSubscriber();
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: _FakeTarget(version: 1),
        subscriber: subscriber,
        poller: _FakePoller(version: 1),
      );
      await svc.start();
      expect(subscriber.disconnectCalls, 0);
      await svc.dispose();
      expect(svc.isRunning, false);
      expect(subscriber.disconnectCalls, 1);
    });

    test('start twice throws StateError', () async {
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: _FakeTarget(version: 1),
        subscriber: _FakeSubscriber(),
        poller: _FakePoller(version: 1),
      );
      await svc.start();
      expect(() => svc.start(), throwsStateError);
      await svc.dispose();
    });

    test('start after dispose throws', () async {
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: _FakeTarget(version: 1),
        subscriber: _FakeSubscriber(),
        poller: _FakePoller(version: 1),
      );
      await svc.start();
      await svc.dispose();
      expect(() => svc.start(), throwsStateError);
    });

    test('dispose is idempotent', () async {
      final subscriber = _FakeSubscriber();
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: _FakeTarget(version: 1),
        subscriber: subscriber,
        poller: _FakePoller(version: 1),
      );
      await svc.start();
      await svc.dispose();
      await svc.dispose();
      await svc.dispose();
      expect(subscriber.disconnectCalls, 1);
    });

    test('real periodic timer drives pollOnce (integration-style)',
        () async {
      final subscriber = _FakeSubscriber();
      final target = _FakeTarget(version: 1);
      final poller = _FakePoller(version: 2);
      final svc = GameRealtimeService(
        gameId: 'g-1',
        target: target,
        subscriber: subscriber,
        poller: poller,
        pollInterval: const Duration(milliseconds: 30),
      );
      await svc.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(target.refreshCount, greaterThanOrEqualTo(1));
      await svc.dispose();
    });
  });

  group('CompositeVersionPoller fallback', () {
    test('returns redis value when redis succeeds', () async {
      final poller = CompositeVersionPoller(
        redis: _StaticRedis(value: 7),
        supabase: _StaticSupabase(value: 2),
      );
      expect(await poller.pollVersion('g-1'), 7);
    });

    test('falls back to Supabase when Redis returns null (miss)',
        () async {
      final poller = CompositeVersionPoller(
        redis: _StaticRedis(value: null),
        supabase: _StaticSupabase(value: 11),
      );
      expect(await poller.pollVersion('g-1'), 11);
    });

    test('falls back to Supabase when Redis throws', () async {
      final poller = CompositeVersionPoller(
        redis: _ThrowingRedis(),
        supabase: _StaticSupabase(value: 4),
      );
      expect(await poller.pollVersion('g-1'), 4);
    });

    test('returns null when both sources fail', () async {
      final poller = CompositeVersionPoller(
        redis: _ThrowingRedis(),
        supabase: _ThrowingSupabase(),
      );
      expect(await poller.pollVersion('g-1'), isNull);
    });
  });

  group('UpstashRedisVersionReader', () {
    test('parses {"result": "5"} to 5', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/get/game_version:g-1');
        expect(req.headers['Authorization'], 'Bearer TOK');
        return http.Response(jsonEncode({'result': '5'}), 200);
      });
      final reader = UpstashRedisVersionReader(
        url: 'https://upstash.example.io',
        token: 'TOK',
        client: client,
      );
      expect(await reader.readVersion('g-1'), 5);
    });

    test('parses {"result": 5} (integer body) to 5', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode({'result': 5}), 200);
      });
      final reader = UpstashRedisVersionReader(
        url: 'https://upstash.example.io',
        token: 'TOK',
        client: client,
      );
      expect(await reader.readVersion('g-1'), 5);
    });

    test('returns null when result is null (cache miss)', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode({'result': null}), 200);
      });
      final reader = UpstashRedisVersionReader(
        url: 'https://upstash.example.io',
        token: 'TOK',
        client: client,
      );
      expect(await reader.readVersion('g-1'), isNull);
    });

    test('returns null on non-200 (service unreachable)', () async {
      final client = MockClient((req) async {
        return http.Response('nope', 503);
      });
      final reader = UpstashRedisVersionReader(
        url: 'https://upstash.example.io',
        token: 'TOK',
        client: client,
      );
      expect(await reader.readVersion('g-1'), isNull);
    });

    test('returns null on malformed integer string', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode({'result': 'not-a-number'}), 200);
      });
      final reader = UpstashRedisVersionReader(
        url: 'https://upstash.example.io',
        token: 'TOK',
        client: client,
      );
      expect(await reader.readVersion('g-1'), isNull);
    });
  });
}

// =========================================================================
// Test doubles
// =========================================================================

class _FakeSubscriber implements RealtimeSubscriber {
  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();
  int disconnectCalls = 0;

  void emit(RealtimeEvent event) => _controller.add(event);
  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<RealtimeEvent> subscribeToGame(String gameId) => _controller.stream;

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    await _controller.close();
  }
}

class _FakeTarget implements GameRealtimeTarget {
  _FakeTarget({required this.version});

  int? version;
  final List<Game> gameUpdates = [];
  final List<GamePlayer> playerUpserts = [];
  final List<String> playerRemovals = [];
  final List<Order> orderUpserts = [];
  final List<String> orderRemovals = [];
  final List<Execution> executionInserts = [];
  int refreshCount = 0;

  int get everythingSeen =>
      gameUpdates.length +
      playerUpserts.length +
      playerRemovals.length +
      orderUpserts.length +
      orderRemovals.length +
      executionInserts.length;

  @override
  int? get currentVersion => version;

  @override
  void applyGameUpdate(Game game) {
    gameUpdates.add(game);
    version = game.stateVersion;
  }

  @override
  void applyPlayerUpsert(GamePlayer player) => playerUpserts.add(player);

  @override
  void applyPlayerRemoval(String playerId) => playerRemovals.add(playerId);

  @override
  void applyOrderUpsert(Order order) => orderUpserts.add(order);

  @override
  void applyOrderRemoval(String orderId) => orderRemovals.add(orderId);

  @override
  void applyExecutionInsert(Execution execution) =>
      executionInserts.add(execution);

  @override
  Future<void> refreshAll() async {
    refreshCount++;
  }
}

class _FakePoller implements VersionPoller {
  _FakePoller({required this.version});
  int? version;

  @override
  Future<int?> pollVersion(String gameId) async => version;
}

class _StaticRedis implements RedisVersionReader {
  _StaticRedis({required this.value});
  final int? value;
  @override
  Future<int?> readVersion(String gameId) async => value;
}

class _StaticSupabase implements SupabaseVersionReader {
  _StaticSupabase({required this.value});
  final int? value;
  @override
  Future<int?> readVersion(String gameId) async => value;
}

class _ThrowingRedis implements RedisVersionReader {
  @override
  Future<int?> readVersion(String gameId) async =>
      throw StateError('redis down');
}

class _ThrowingSupabase implements SupabaseVersionReader {
  @override
  Future<int?> readVersion(String gameId) async =>
      throw StateError('supabase down');
}
