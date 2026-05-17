import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/models/order.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_order_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/order_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/supabase_order_repository.dart';
import 'package:uncertain_envelopes_2/services/supabase_order_gateway.dart';

Order _order({
  required String id,
  String gameId = 'g-1',
  String playerId = 'p-1',
  OrderType type = OrderType.limitBuy,
  OrderStatus status = OrderStatus.orderResting,
  DateTime? createdAt,
  DateTime? updatedAt,
  double? price = 100,
  int qty = 5,
}) {
  final c = createdAt ?? DateTime.utc(2026, 1, 1, 10);
  return Order(
    orderId: id,
    createdByPlayerId: playerId,
    gameId: gameId,
    type: type,
    quantityInitial: qty,
    quantityCurrent: qty,
    pricePerStock: type.isMarket ? null : price,
    status: status,
    orderCreatedAt: c,
    orderUpdatedAt: updatedAt ?? c,
  );
}

class _Fixture {
  _Fixture({required this.repo, required this.seed});
  final OrderRepository repo;
  final void Function(Iterable<Order>) seed;
}

void main() {
  group('InMemoryOrderRepository', () {
    _runContract(() {
      final repo = InMemoryOrderRepository();
      return _Fixture(repo: repo, seed: repo.seedOrders);
    });
  });

  group('SupabaseOrderRepository (fake gateway)', () {
    _runContract(() {
      final gateway = _FakeOrderGateway();
      return _Fixture(
        repo: SupabaseOrderRepository(gateway),
        seed: gateway.seed,
      );
    });
  });
}

void _runContract(_Fixture Function() build) {
  late _Fixture fix;
  setUp(() => fix = build());

  test('fetchOrdersForGame returns only matching game, FIFO sorted',
      () async {
    fix.seed([
      _order(
        id: 'o-3',
        createdAt: DateTime.utc(2026, 1, 1, 10, 3),
      ),
      _order(
        id: 'o-1',
        createdAt: DateTime.utc(2026, 1, 1, 10, 1),
      ),
      _order(
        id: 'o-other-game',
        gameId: 'g-2',
        createdAt: DateTime.utc(2026, 1, 1, 10, 2),
      ),
      _order(
        id: 'o-2',
        createdAt: DateTime.utc(2026, 1, 1, 10, 2),
      ),
    ]);
    final ids = (await fix.repo.fetchOrdersForGame('g-1'))
        .map((o) => o.orderId)
        .toList();
    expect(ids, ['o-1', 'o-2', 'o-3']);
  });

  test('fetchOrdersForGame returns empty for unknown game', () async {
    fix.seed([_order(id: 'o-1')]);
    expect(await fix.repo.fetchOrdersForGame('no-such-game'), isEmpty);
  });

  test('fetchPersonalOrders scopes to (gameId, playerId) and sorts desc',
      () async {
    fix.seed([
      _order(
        id: 'o-mine-old',
        playerId: 'p-1',
        createdAt: DateTime.utc(2026, 1, 1, 10, 1),
      ),
      _order(
        id: 'o-mine-new',
        playerId: 'p-1',
        createdAt: DateTime.utc(2026, 1, 1, 10, 3),
      ),
      _order(
        id: 'o-other',
        playerId: 'p-2',
        createdAt: DateTime.utc(2026, 1, 1, 10, 2),
      ),
      _order(
        id: 'o-other-game',
        playerId: 'p-1',
        gameId: 'g-2',
        createdAt: DateTime.utc(2026, 1, 1, 10, 4),
      ),
    ]);
    final ids = (await fix.repo.fetchPersonalOrders(
      gameId: 'g-1',
      playerId: 'p-1',
    ))
        .map((o) => o.orderId)
        .toList();
    expect(ids, ['o-mine-new', 'o-mine-old']);
  });

  test('fetchPendingOrdersAcrossGames filters by non-terminal status',
      () async {
    fix.seed([
      _order(
        id: 'o-resting',
        status: OrderStatus.orderResting,
        createdAt: DateTime.utc(2026, 1, 1, 10, 1),
      ),
      _order(
        id: 'o-in-queue',
        status: OrderStatus.inQueue,
        createdAt: DateTime.utc(2026, 1, 1, 10, 2),
      ),
      _order(
        id: 'o-processing',
        status: OrderStatus.beingProcessed,
        createdAt: DateTime.utc(2026, 1, 1, 10, 3),
      ),
      _order(
        id: 'o-closed',
        status: OrderStatus.orderClosed,
        createdAt: DateTime.utc(2026, 1, 1, 10, 4),
      ),
      _order(
        id: 'o-cancelled',
        status: OrderStatus.cancelled,
        createdAt: DateTime.utc(2026, 1, 1, 10, 5),
      ),
      _order(
        id: 'o-game-ended',
        status: OrderStatus.gameEnded,
        createdAt: DateTime.utc(2026, 1, 1, 10, 6),
      ),
      _order(
        id: 'o-other-player',
        playerId: 'p-2',
        status: OrderStatus.orderResting,
        createdAt: DateTime.utc(2026, 1, 1, 10, 7),
      ),
    ]);
    final ids = (await fix.repo.fetchPendingOrdersAcrossGames('p-1'))
        .map((o) => o.orderId)
        .toSet();
    expect(ids, {'o-resting', 'o-in-queue', 'o-processing'});
  });

  test('fetchPendingOrdersAcrossGames spans games', () async {
    fix.seed([
      _order(
        id: 'o-g1',
        status: OrderStatus.orderResting,
        gameId: 'g-1',
      ),
      _order(
        id: 'o-g2',
        status: OrderStatus.orderResting,
        gameId: 'g-2',
      ),
      _order(
        id: 'o-g3',
        status: OrderStatus.inQueue,
        gameId: 'g-3',
      ),
    ]);
    final ids = (await fix.repo.fetchPendingOrdersAcrossGames('p-1'))
        .map((o) => o.orderId)
        .toSet();
    expect(ids, {'o-g1', 'o-g2', 'o-g3'});
  });

  test(
    'fetchTerminalOrdersUpdatedSinceAcrossGames returns terminal in window',
    () async {
    final t0 = DateTime.utc(2026, 6, 1, 12);
    fix.seed([
      _order(
        id: 'o-old',
        status: OrderStatus.orderClosed,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 6, 1, 11, 0),
      ),
      _order(
        id: 'o-recent',
        status: OrderStatus.cancelled,
        createdAt: DateTime.utc(2026, 6, 1, 11, 30),
        updatedAt: DateTime.utc(2026, 6, 1, 11, 45),
      ),
      _order(
        id: 'o-active',
        status: OrderStatus.orderResting,
        createdAt: DateTime.utc(2026, 6, 1, 11, 50),
        updatedAt: DateTime.utc(2026, 6, 1, 11, 50),
      ),
    ]);
    final since = DateTime.utc(2026, 6, 1, 11, 40);
    final ids = (await fix.repo.fetchTerminalOrdersUpdatedSinceAcrossGames(
      'p-1',
      since,
    ))
        .map((o) => o.orderId)
        .toList();
    expect(ids, ['o-recent']);
  });

  test('empty state returns empty list (never null)', () async {
    expect(await fix.repo.fetchOrdersForGame('anything'), isEmpty);
    expect(
      await fix.repo.fetchPersonalOrders(gameId: 'g', playerId: 'p'),
      isEmpty,
    );
    expect(await fix.repo.fetchPendingOrdersAcrossGames('p'), isEmpty);
    expect(
      await fix.repo.fetchTerminalOrdersUpdatedSinceAcrossGames(
        'p',
        DateTime.utc(2020),
      ),
      isEmpty,
    );
  });
}

class _FakeOrderGateway implements SupabaseOrderGateway {
  final List<Order> _orders = [];

  void seed(Iterable<Order> orders) => _orders.addAll(orders);

  @override
  Future<List<Map<String, dynamic>>> fetchOrderRowsForGame(
    String gameId,
  ) async {
    final filtered = _orders.where((o) => o.gameId == gameId).toList()
      ..sort((a, b) => a.orderCreatedAt.compareTo(b.orderCreatedAt));
    return filtered.map((o) => o.toJson()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPersonalOrderRows({
    required String gameId,
    required String playerId,
  }) async {
    final filtered = _orders
        .where((o) =>
            o.gameId == gameId && o.createdByPlayerId == playerId)
        .toList()
      ..sort((a, b) => b.orderCreatedAt.compareTo(a.orderCreatedAt));
    return filtered.map((o) => o.toJson()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPendingOrderRowsAcrossGames(
    String playerId,
  ) async {
    final filtered = _orders
        .where((o) =>
            o.createdByPlayerId == playerId && o.status.isActive)
        .toList()
      ..sort((a, b) => b.orderCreatedAt.compareTo(a.orderCreatedAt));
    return filtered.map((o) => o.toJson()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTerminalOrderRowsUpdatedSinceAcrossGames(
    String playerId,
    DateTime sinceUtc,
  ) async {
    final since = sinceUtc.toUtc();
    final filtered = _orders
        .where(
          (o) =>
              o.createdByPlayerId == playerId &&
              o.status.isTerminal &&
              !o.orderUpdatedAt.toUtc().isBefore(since),
        )
        .toList()
      ..sort((a, b) => b.orderUpdatedAt.compareTo(a.orderUpdatedAt));
    return filtered.map((o) => o.toJson()).toList();
  }
}
