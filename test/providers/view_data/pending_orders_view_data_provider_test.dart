import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';
import 'package:uncertain_envelopes_2/data/models/order.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_order_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/trading_repository_providers.dart';
import 'package:uncertain_envelopes_2/providers/view_data/pending_orders_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';

void main() {
  test('pendingOrdersViewData joins game metadata to orders', () async {
    final auth = InMemoryAuthRepository();
    final commands = InMemoryCommandRepository();
    final games = InMemoryGameRepository(commandRepository: commands);
    final orders = InMemoryOrderRepository();
    final t = DateTime.utc(2026, 2, 1, 12);
    auth.setSessionPlayerForTest(
      Player(
        playerId: 'p1',
        username: 'u1',
        createdAt: t,
        email: 'e@test.com',
      ),
    );
    games.seedGame(
      Game(
        gameId: 'g-x',
        gameName: 'My Game',
        gameDescription: 'Desc',
        gameCreatedAt: t,
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        joiningCode: 'ABCDE',
        endCondition: EndCondition.endless,
        gameState: GameState.tradingStarted,
        adminPlayerId: 'p1',
        stateVersion: 1,
        updatedAt: t,
        startTime: t,
      ),
    );
    games.seedMembership('g-x', 'p1');
    orders.seedOrders([
      Order(
        orderId: 'o1',
        createdByPlayerId: 'p1',
        gameId: 'g-x',
        type: OrderType.limitBuy,
        quantityInitial: 2,
        quantityCurrent: 2,
        pricePerStock: 50,
        status: OrderStatus.orderResting,
        orderCreatedAt: t,
        orderUpdatedAt: t,
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        gameRepositoryProvider.overrideWithValue(games),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final data = await container.read(pendingOrdersViewDataProvider.future);

    expect(data, isA<PendingOrdersScreenData>());
    expect(data.items.single.gameId, 'g-x');
    expect(data.items.single.gameTitle, 'My Game');
    expect(data.items.single.gameDescription, 'Desc');
    expect(data.items.single.order.id, 'o1');

    expect(data.tradingGamesForNewOrder, hasLength(1));
    expect(data.tradingGamesForNewOrder.single.gameId, 'g-x');
    expect(data.tradingGamesForNewOrder.single.gameTitle, 'My Game');
    expect(data.tradingGamesForNewOrder.single.gameDescription, 'Desc');
  });

  test('includes terminal orders updated within the last minute', () async {
    final auth = InMemoryAuthRepository();
    final commands = InMemoryCommandRepository();
    final games = InMemoryGameRepository(commandRepository: commands);
    final orders = InMemoryOrderRepository();
    final t = DateTime.utc(2026, 2, 1, 12);
    final now = DateTime.now().toUtc();
    auth.setSessionPlayerForTest(
      Player(
        playerId: 'p1',
        username: 'u1',
        createdAt: t,
        email: 'e@test.com',
      ),
    );
    games.seedGame(
      Game(
        gameId: 'g-x',
        gameName: 'My Game',
        gameDescription: 'Desc',
        gameCreatedAt: t,
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 4,
        joiningCode: 'ABCDE',
        endCondition: EndCondition.endless,
        gameState: GameState.tradingStarted,
        adminPlayerId: 'p1',
        stateVersion: 1,
        updatedAt: t,
        startTime: t,
      ),
    );
    games.seedMembership('g-x', 'p1');
    orders.seedOrders([
      Order(
        orderId: 'o-active',
        createdByPlayerId: 'p1',
        gameId: 'g-x',
        type: OrderType.limitBuy,
        quantityInitial: 2,
        quantityCurrent: 2,
        pricePerStock: 50,
        status: OrderStatus.orderResting,
        orderCreatedAt: now,
        orderUpdatedAt: now,
      ),
      Order(
        orderId: 'o-closed-recent',
        createdByPlayerId: 'p1',
        gameId: 'g-x',
        type: OrderType.limitSell,
        quantityInitial: 1,
        quantityCurrent: 0,
        pricePerStock: 40,
        status: OrderStatus.orderClosed,
        orderCreatedAt: t,
        orderUpdatedAt: now.subtract(const Duration(seconds: 15)),
      ),
      Order(
        orderId: 'o-closed-stale',
        createdByPlayerId: 'p1',
        gameId: 'g-x',
        type: OrderType.limitSell,
        quantityInitial: 1,
        quantityCurrent: 0,
        pricePerStock: 40,
        status: OrderStatus.orderClosed,
        orderCreatedAt: t,
        orderUpdatedAt: now.subtract(const Duration(minutes: 5)),
      ),
    ]);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        gameRepositoryProvider.overrideWithValue(games),
        orderRepositoryProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.future);
    final data = await container.read(pendingOrdersViewDataProvider.future);

    final ids = data.items.map((e) => e.order.id).toSet();
    expect(ids, {'o-active', 'o-closed-recent'});
    expect(
      data.items
          .firstWhere((e) => e.order.id == 'o-closed-recent')
          .isRecentlyClosed,
      isTrue,
    );
    expect(
      data.items.firstWhere((e) => e.order.id == 'o-active').isRecentlyClosed,
      isFalse,
    );
  });
}
