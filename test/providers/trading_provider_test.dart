import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/core/chart/chart_axis.dart';
import 'package:uncertain_envelopes_2/core/chart/price_chart_point.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/models/execution.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/order.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_execution_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_order_repository.dart';
import 'package:uncertain_envelopes_2/providers/clock_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/trading_provider.dart';
import 'package:uncertain_envelopes_2/providers/trading_repository_providers.dart';

Order _resting({
  required String id,
  required OrderType type,
  required double price,
  required int qty,
  String gameId = 'g-1',
  String playerId = 'p-1',
  DateTime? createdAt,
}) {
  return Order(
    orderId: id,
    createdByPlayerId: playerId,
    gameId: gameId,
    type: type,
    quantityInitial: qty,
    quantityCurrent: qty,
    pricePerStock: price,
    status: OrderStatus.orderResting,
    orderCreatedAt: createdAt ?? DateTime.utc(2026, 1, 1, 10),
    orderUpdatedAt: createdAt ?? DateTime.utc(2026, 1, 1, 10),
  );
}

Execution _exec({
  required String id,
  required double price,
  required DateTime at,
  String gameId = 'g-1',
}) {
  return Execution(
    executionsId: id,
    executionsGameId: gameId,
    buyOrderId: 'buy-$id',
    sellOrderId: 'sell-$id',
    quantity: 1,
    executionPrice: price,
    executedAt: at,
  );
}

Game _gameTrading({
  DateTime? start,
  DateTime? endActual,
}) {
  return Game(
    gameId: 'g-1',
    gameName: 'G',
    gameCreatedAt: DateTime.utc(2026, 1, 1, 10),
    gameSecurity: GameSecurity.public,
    isRanked: IsRanked.casual,
    gameMaxPlayers: 10,
    joiningCode: 'AB12C',
    endCondition: EndCondition.endless,
    gameState: endActual == null
        ? GameState.tradingStarted
        : GameState.tradingEnded,
    adminPlayerId: 'p-admin',
    stateVersion: 1,
    updatedAt: DateTime.utc(2026, 1, 1, 10),
    startTime: start ?? DateTime.utc(2026, 1, 1, 10),
    endTimeActual: endActual,
  );
}

void main() {
  late InMemoryGameRepository games;
  late InMemoryOrderRepository orders;
  late InMemoryExecutionRepository executions;
  late InMemoryCommandRepository commands;

  setUp(() {
    commands = InMemoryCommandRepository();
    games = InMemoryGameRepository(commandRepository: commands);
    orders = InMemoryOrderRepository();
    executions = InMemoryExecutionRepository();
  });

  ProviderContainer makeContainer({DateTime Function()? clock}) {
    return ProviderContainer(
      overrides: [
        gameRepositoryProvider.overrideWithValue(games),
        orderRepositoryProvider.overrideWithValue(orders),
        executionRepositoryProvider.overrideWithValue(executions),
        if (clock != null) clockProvider.overrideWith((_) => clock),
      ],
    );
  }

  // Note: the pure division-minute lookup function lives at
  // `core/chart/chart_axis.dart` (chartDivisionMinutesFromElapsed) and is
  // exhaustively covered by `test/core/chart/chart_axis_test.dart`. The
  // provider-side coverage below verifies the *integration* — that the
  // provider feeds elapsed/points to the canonical factory correctly,
  // not that the lookup itself is right.

  group('orderBookProvider', () {
    test('splits bids desc + asks asc and aggregates per price level',
        () async {
      games.seedGame(_gameTrading());
      orders.seedOrders([
        _resting(id: 'b1', type: OrderType.limitBuy, price: 99, qty: 3),
        _resting(id: 'b2', type: OrderType.limitBuy, price: 99, qty: 2),
        _resting(id: 'b3', type: OrderType.limitBuy, price: 98, qty: 1),
        _resting(id: 'a1', type: OrderType.limitSell, price: 101, qty: 5),
        _resting(id: 'a2', type: OrderType.limitSell, price: 102, qty: 4),
        _resting(id: 'a3', type: OrderType.limitSell, price: 101, qty: 1),
      ]);
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);

      final book = container.read(orderBookProvider('g-1'));
      expect(book.bids.map((l) => (l.price, l.totalQuantity)).toList(),
          [(99.0, 5), (98.0, 1)]);
      expect(book.asks.map((l) => (l.price, l.totalQuantity)).toList(),
          [(101.0, 6), (102.0, 4)]);
      expect(book.bestBid?.price, 99);
      expect(book.bestAsk?.price, 101);
    });

    test('ignores non-resting orders and market orders', () async {
      games.seedGame(_gameTrading());
      orders.seedOrders([
        _resting(id: 'r1', type: OrderType.limitBuy, price: 99, qty: 3),
        // Closed order — excluded.
        Order(
          orderId: 'c1',
          createdByPlayerId: 'p-1',
          gameId: 'g-1',
          type: OrderType.limitBuy,
          quantityInitial: 5,
          quantityCurrent: 0,
          pricePerStock: 100,
          status: OrderStatus.orderClosed,
          orderCreatedAt: DateTime.utc(2026, 1, 1, 10),
          orderUpdatedAt: DateTime.utc(2026, 1, 1, 10),
        ),
        // Cancelled — excluded.
        Order(
          orderId: 'x1',
          createdByPlayerId: 'p-1',
          gameId: 'g-1',
          type: OrderType.limitSell,
          quantityInitial: 5,
          quantityCurrent: 5,
          pricePerStock: 101,
          status: OrderStatus.cancelled,
          orderCreatedAt: DateTime.utc(2026, 1, 1, 10),
          orderUpdatedAt: DateTime.utc(2026, 1, 1, 10),
        ),
      ]);
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);
      final book = container.read(orderBookProvider('g-1'));
      expect(book.bids.single.price, 99);
      expect(book.asks, isEmpty);
    });

    test('empty book when no orders', () async {
      games.seedGame(_gameTrading());
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);
      expect(container.read(orderBookProvider('g-1')).isEmpty, true);
    });
  });

  group('Orders notifier deltas', () {
    test('upsert adds new / replaces existing by orderId', () async {
      games.seedGame(_gameTrading());
      orders.seedOrders([
        _resting(id: 'r1', type: OrderType.limitBuy, price: 99, qty: 3),
      ]);
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);

      final notifier = container.read(ordersProvider('g-1').notifier);
      notifier.upsert(_resting(
        id: 'r2',
        type: OrderType.limitSell,
        price: 102,
        qty: 1,
      ));
      expect(container.read(ordersProvider('g-1')).valueOrNull!.length, 2);

      notifier.upsert(_resting(
        id: 'r1',
        type: OrderType.limitBuy,
        price: 100,
        qty: 1,
      ));
      final after = container.read(ordersProvider('g-1')).valueOrNull!;
      expect(after.length, 2);
      expect(
        after.firstWhere((o) => o.orderId == 'r1').pricePerStock,
        100,
      );
    });

    test('remove removes by orderId', () async {
      games.seedGame(_gameTrading());
      orders.seedOrders([
        _resting(id: 'r1', type: OrderType.limitBuy, price: 99, qty: 3),
      ]);
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);
      container.read(ordersProvider('g-1').notifier).remove('r1');
      expect(container.read(ordersProvider('g-1')).valueOrNull, isEmpty);
    });

    test('upsert ignores orders for a different gameId', () async {
      games.seedGame(_gameTrading());
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);
      container.read(ordersProvider('g-1').notifier).upsert(_resting(
            id: 'other',
            gameId: 'g-other',
            type: OrderType.limitBuy,
            price: 99,
            qty: 1,
          ));
      expect(container.read(ordersProvider('g-1')).valueOrNull, isEmpty);
    });
  });

  group('personalOrdersProvider', () {
    test('filters by playerId and sorts newest first', () async {
      games.seedGame(_gameTrading());
      orders.seedOrders([
        _resting(
          id: 'mine-old',
          type: OrderType.limitBuy,
          price: 99,
          qty: 1,
          playerId: 'p-me',
          createdAt: DateTime.utc(2026, 1, 1, 10, 1),
        ),
        _resting(
          id: 'mine-new',
          type: OrderType.limitSell,
          price: 101,
          qty: 2,
          playerId: 'p-me',
          createdAt: DateTime.utc(2026, 1, 1, 10, 3),
        ),
        _resting(
          id: 'other',
          type: OrderType.limitBuy,
          price: 98,
          qty: 5,
          playerId: 'p-them',
          createdAt: DateTime.utc(2026, 1, 1, 10, 2),
        ),
      ]);
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);
      final mine = container.read(
        personalOrdersProvider(gameId: 'g-1', playerId: 'p-me'),
      );
      expect(mine.map((o) => o.orderId).toList(), ['mine-new', 'mine-old']);
    });

    test('empty when player has no orders', () async {
      games.seedGame(_gameTrading());
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(ordersProvider('g-1').future);
      expect(
        container.read(
          personalOrdersProvider(gameId: 'g-1', playerId: 'p-none'),
        ),
        isEmpty,
      );
    });
  });

  group('Executions notifier + executionHistoryProvider', () {
    test('empty when game has not started (no start_time)', () async {
      // state=created -> startTime stays null.
      games.seedGame(Game(
        gameId: 'g-1',
        gameName: 'G',
        gameCreatedAt: DateTime.utc(2026, 1, 1, 10),
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 10,
        joiningCode: 'AB12C',
        endCondition: EndCondition.endless,
        gameState: GameState.created,
        adminPlayerId: 'p-admin',
        stateVersion: 1,
        updatedAt: DateTime.utc(2026, 1, 1, 10),
      ));
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      expect(container.read(executionHistoryProvider('g-1')), isEmpty);
    });

    test('computes timeElapsed = executedAt - start_time, sorted asc',
        () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      executions.seedExecutions([
        _exec(id: 'e3', price: 105, at: start.add(const Duration(seconds: 30))),
        _exec(id: 'e1', price: 100, at: start.add(const Duration(seconds: 10))),
        _exec(id: 'e2', price: 102, at: start.add(const Duration(seconds: 20))),
      ]);
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      final points = container.read(executionHistoryProvider('g-1'));
      expect(points.map((p) => p.timeElapsed.inSeconds).toList(),
          [10, 20, 30]);
      expect(points.map((p) => p.price).toList(), [100.0, 102.0, 105.0]);
    });

    test('add ignores duplicate executionsId', () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      final notifier = container.read(executionsProvider('g-1').notifier);
      final exec = _exec(
        id: 'e1',
        price: 100,
        at: start.add(const Duration(seconds: 5)),
      );
      notifier.add(exec);
      notifier.add(exec);
      notifier.add(exec);
      expect(
        container.read(executionsProvider('g-1')).valueOrNull!.length,
        1,
      );
    });

    test('add ignores executions for a different game', () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      container.read(executionsProvider('g-1').notifier).add(_exec(
            id: 'stray',
            price: 200,
            at: start,
            gameId: 'g-other',
          ));
      expect(container.read(executionsProvider('g-1')).valueOrNull, isEmpty);
    });
  });

  group('chartSessionElapsedProvider', () {
    test('uses end_time_actual - start_time after trading has ended',
        () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      final end = start.add(const Duration(minutes: 8));
      games.seedGame(_gameTrading(start: start, endActual: end));
      final container = makeContainer(
        // Clock far past the game end; should NOT affect elapsed.
        clock: () => start.add(const Duration(hours: 5)),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      expect(
        container.read(chartSessionElapsedProvider('g-1')),
        const Duration(minutes: 8),
      );
    });

    test('uses now() - start_time during active trading', () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      final container = makeContainer(
        clock: () => start.add(const Duration(minutes: 25)),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      expect(
        container.read(chartSessionElapsedProvider('g-1')),
        const Duration(minutes: 25),
      );
    });

    test('clamps to zero when clock < start_time (clock skew protection)',
        () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      final container = makeContainer(
        clock: () => start.subtract(const Duration(seconds: 30)),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      expect(
        container.read(chartSessionElapsedProvider('g-1')),
        Duration.zero,
      );
    });
  });

  group('chartAxisProvider', () {
    // The provider is a thin wrapper around
    // ChartAxisConfig.fromExecutionHistory(elapsed, points). Its job is to
    // (a) feed the right inputs in, and (b) emit the *exact* same
    // ChartAxisConfig the trading screen builds today from mocks — so the
    // chart UI cannot move by a single pixel under provider wiring.
    // Coverage of the factory's own padding/maxX math lives in
    // test/core/chart/chart_axis_test.dart and
    // test/ui/widgets/price_chart_test.dart — not duplicated here.

    test('forwards inputs to ChartAxisConfig.fromExecutionHistory verbatim',
        () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      executions.seedExecutions([
        _exec(id: 'e1', price: 100, at: start.add(const Duration(seconds: 5))),
        _exec(id: 'e2', price: 110, at: start.add(const Duration(seconds: 10))),
      ]);
      final container = makeContainer(
        clock: () => start.add(const Duration(minutes: 25)),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);

      final providerAxis = container.read(chartAxisProvider('g-1'));
      final providerPoints =
          container.read(executionHistoryProvider('g-1'));
      final providerElapsed =
          container.read(chartSessionElapsedProvider('g-1'));

      // The provider's axis must equal what the screen would produce
      // calling the factory directly with the same provider-supplied
      // inputs — full-field equality, not field-by-field.
      final expected = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: providerElapsed,
        points: providerPoints,
      );
      expect(providerAxis.divisionMinutes, expected.divisionMinutes);
      expect(providerAxis.maxXMinutes, expected.maxXMinutes);
      expect(providerAxis.minPrice, expected.minPrice);
      expect(providerAxis.maxPrice, expected.maxPrice);
    });

    test('division minutes derive from elapsed (8 min -> 2)', () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      final end = start.add(const Duration(minutes: 8));
      games.seedGame(_gameTrading(start: start, endActual: end));
      final container = makeContainer(
        clock: () => start.add(const Duration(hours: 5)),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      expect(container.read(chartAxisProvider('g-1')).divisionMinutes, 2);
    });

    test('division minutes derive from elapsed (25 min -> 5)', () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      final container = makeContainer(
        clock: () => start.add(const Duration(minutes: 25)),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      expect(container.read(chartAxisProvider('g-1')).divisionMinutes, 5);
    });

    test('price axis defaults to [0, 1] when no executions', () async {
      final start = DateTime.utc(2026, 1, 1, 10);
      games.seedGame(_gameTrading(start: start));
      final container = makeContainer(
        clock: () => start.add(const Duration(minutes: 1)),
      );
      addTearDown(container.dispose);
      await container.read(currentGameProvider('g-1').future);
      await container.read(executionsProvider('g-1').future);
      final axis = container.read(chartAxisProvider('g-1'));
      expect(axis.minPrice, 0);
      expect(axis.maxPrice, 1);
    });

    test(
      'single-price widens via the 0.5 padding floor (not a zero-range axis)',
      () async {
        final start = DateTime.utc(2026, 1, 1, 10);
        games.seedGame(_gameTrading(start: start));
        executions.seedExecutions([
          _exec(
            id: 'e1',
            price: 100,
            at: start.add(const Duration(seconds: 5)),
          ),
        ]);
        final container = makeContainer(
          clock: () => start.add(const Duration(minutes: 1)),
        );
        addTearDown(container.dispose);
        await container.read(currentGameProvider('g-1').future);
        await container.read(executionsProvider('g-1').future);
        final axis = container.read(chartAxisProvider('g-1'));
        expect(axis.minPrice, lessThan(axis.maxPrice));
        // Floor padding = 0.5 either side; matches what fromExecutionHistory
        // produces for a single-point series.
        expect(axis.minPrice, closeTo(99.5, 0.001));
        expect(axis.maxPrice, closeTo(100.5, 0.001));
      },
    );
  });
}
