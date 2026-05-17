import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order_from_order.dart';
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
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_command_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_execution_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_game_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_order_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_player_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/command_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/player_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/trading_repository_providers.dart';
import 'package:uncertain_envelopes_2/providers/view_data/trading_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';

import '../../support/golden_trading_minimal_seed.dart'
    show GoldenTradingMinimalHarness, GoldenTradingMinimalSeed;

void main() {
  group('personalOrderFromOrder', () {
    test('maps resting limit sell', () {
      final o = Order(
        orderId: 'o1',
        createdByPlayerId: 'p1',
        gameId: 'g1',
        type: OrderType.limitSell,
        quantityInitial: 4,
        quantityCurrent: 4,
        pricePerStock: 101,
        status: OrderStatus.orderResting,
        orderCreatedAt: DateTime.utc(2026, 2, 1, 10),
        orderUpdatedAt: DateTime.utc(2026, 2, 1, 10),
      );
      final p = personalOrderFromOrder(o);
      expect(p.id, 'o1');
      expect(p.side, PersonalOrderSide.sell);
      expect(p.orderType, PersonalOrderType.limit);
      expect(p.status, PersonalOrderStatus.resting);
      expect(p.limitPrice, 101);
    });
  });

  group('tradingViewDataProvider', () {
    test('builds view data from seeded repositories', () async {
      final commands = InMemoryCommandRepository();
      final games = InMemoryGameRepository(commandRepository: commands);
      final orders = InMemoryOrderRepository();
      final executions = InMemoryExecutionRepository();
      final authRepo = InMemoryAuthRepository();
      authRepo.setSessionPlayerForTest(
        Player(
          playerId: 'viewer-1',
          username: 'viewer',
          createdAt: DateTime.utc(2026, 1, 1),
          email: 'v@test.com',
        ),
      );

      final start = DateTime.utc(2026, 3, 1, 12);
      games.seedGame(
        Game(
          gameId: 'tg1',
          gameName: 'Trading Seed',
          gameDescription: 'D',
          gameCreatedAt: start,
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.casual,
          gameMaxPlayers: 4,
          joiningCode: 'AAAAA',
          endCondition: EndCondition.endless,
          gameState: GameState.tradingStarted,
          adminPlayerId: 'viewer-1',
          stateVersion: 1,
          updatedAt: start,
          startTime: start,
        ),
      );
      games.seedGamePlayer(
        GamePlayer(
          gamesPlayersRowId: 'gp1',
          mapGameId: 'tg1',
          mapPlayerId: 'viewer-1',
          lobbyStatus: LobbyStatus.playing,
          joinedAt: start,
          isAdmin: true,
          deltaCash: 50,
          deltaEnvelopes: -2,
          pnl: 0,
        ),
      );

      orders.seedOrders([
        Order(
          orderId: 'sell-rest',
          createdByPlayerId: 'other',
          gameId: 'tg1',
          type: OrderType.limitSell,
          quantityInitial: 10,
          quantityCurrent: 10,
          pricePerStock: 200,
          status: OrderStatus.orderResting,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
        Order(
          orderId: 'buy-mine',
          createdByPlayerId: 'viewer-1',
          gameId: 'tg1',
          type: OrderType.limitBuy,
          quantityInitial: 3,
          quantityCurrent: 3,
          pricePerStock: 199,
          status: OrderStatus.orderResting,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
      ]);

      executions.seedExecution(
        Execution(
          executionsId: 'e1',
          executionsGameId: 'tg1',
          buyOrderId: 'buy-mine',
          sellOrderId: 'sell-rest',
          quantity: 1,
          executionPrice: 200,
          executedAt: start.add(const Duration(minutes: 1)),
        ),
      );

      final playerRepo = InMemoryPlayerRepository()
        ..seedPlayer(
          Player(
            playerId: 'viewer-1',
            username: 'alice',
            createdAt: DateTime.utc(2026, 1, 1),
            email: 'alice@test.com',
          ),
        )
        ..seedPlayer(
          Player(
            playerId: 'other',
            username: 'bob_the_seller',
            createdAt: DateTime.utc(2026, 1, 2),
            email: 'bob@test.com',
          ),
        );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          gameRepositoryProvider.overrideWithValue(games),
          orderRepositoryProvider.overrideWithValue(orders),
          executionRepositoryProvider.overrideWithValue(executions),
          commandRepositoryProvider.overrideWithValue(commands),
          playerRepositoryProvider.overrideWithValue(playerRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final data = await container.read(tradingViewDataProvider('tg1').future);

      expect(data.gameTitle, 'Trading Seed');
      expect(data.isViewerAdmin, isTrue);
      expect(data.currentPlayerId, 'viewer-1');
      expect(data.deltaCash, 50);
      expect(data.deltaEnvelopes, -2);
      expect(data.marketPrice, 200);
      expect(data.personalOrders.length, 1);
      expect(data.personalOrders.single.id, 'buy-mine');
      expect(data.orderBookBids.single.price, 199);
      expect(data.orderBookAsks.single.price, 200);
      expect(data.tradeLogs.length, 1);
      expect(data.tradeLogs.single.price, 200);
      expect(data.tradeLogs.single.quantity, 1);
      expect(data.tradeLogs.single.sellerName, 'bob_the_seller');
      expect(data.tradeLogs.single.buyerName, 'alice');
    });

    test('tradeLogs list newest execution first', () async {
      final commands = InMemoryCommandRepository();
      final games = InMemoryGameRepository(commandRepository: commands);
      final orders = InMemoryOrderRepository();
      final executions = InMemoryExecutionRepository();
      final authRepo = InMemoryAuthRepository();
      authRepo.setSessionPlayerForTest(
        Player(
          playerId: 'viewer-1',
          username: 'viewer',
          createdAt: DateTime.utc(2026, 1, 1),
          email: 'v@test.com',
        ),
      );

      final start = DateTime.utc(2026, 3, 1, 12);
      games.seedGame(
        Game(
          gameId: 'tg-order',
          gameName: 'Order Test',
          gameDescription: 'D',
          gameCreatedAt: start,
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.casual,
          gameMaxPlayers: 4,
          joiningCode: 'ORDR',
          endCondition: EndCondition.endless,
          gameState: GameState.tradingStarted,
          adminPlayerId: 'viewer-1',
          stateVersion: 1,
          updatedAt: start,
          startTime: start,
        ),
      );
      games.seedGamePlayer(
        GamePlayer(
          gamesPlayersRowId: 'gp-o',
          mapGameId: 'tg-order',
          mapPlayerId: 'viewer-1',
          lobbyStatus: LobbyStatus.playing,
          joinedAt: start,
          isAdmin: true,
          deltaCash: 0,
          deltaEnvelopes: 0,
          pnl: 0,
        ),
      );

      orders.seedOrders([
        Order(
          orderId: 'sell-a',
          createdByPlayerId: 'seller-a',
          gameId: 'tg-order',
          type: OrderType.limitSell,
          quantityInitial: 10,
          quantityCurrent: 8,
          pricePerStock: 100,
          status: OrderStatus.orderResting,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
        Order(
          orderId: 'buy-a',
          createdByPlayerId: 'viewer-1',
          gameId: 'tg-order',
          type: OrderType.limitBuy,
          quantityInitial: 2,
          quantityCurrent: 1,
          pricePerStock: 100,
          status: OrderStatus.orderResting,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
        Order(
          orderId: 'sell-b',
          createdByPlayerId: 'seller-b',
          gameId: 'tg-order',
          type: OrderType.limitSell,
          quantityInitial: 10,
          quantityCurrent: 9,
          pricePerStock: 110,
          status: OrderStatus.orderResting,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
        Order(
          orderId: 'buy-b',
          createdByPlayerId: 'viewer-1',
          gameId: 'tg-order',
          type: OrderType.limitBuy,
          quantityInitial: 1,
          quantityCurrent: 0,
          pricePerStock: 110,
          status: OrderStatus.orderClosed,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
      ]);

      executions.seedExecution(
        Execution(
          executionsId: 'e-old',
          executionsGameId: 'tg-order',
          buyOrderId: 'buy-a',
          sellOrderId: 'sell-a',
          quantity: 1,
          executionPrice: 100,
          executedAt: start.add(const Duration(minutes: 1)),
        ),
      );
      executions.seedExecution(
        Execution(
          executionsId: 'e-new',
          executionsGameId: 'tg-order',
          buyOrderId: 'buy-b',
          sellOrderId: 'sell-b',
          quantity: 1,
          executionPrice: 110,
          executedAt: start.add(const Duration(minutes: 9)),
        ),
      );

      final playerRepo = InMemoryPlayerRepository()
        ..seedPlayer(
          Player(
            playerId: 'viewer-1',
            username: 'alice',
            createdAt: DateTime.utc(2026, 1, 1),
            email: 'alice@test.com',
          ),
        )
        ..seedPlayer(
          Player(
            playerId: 'seller-a',
            username: 'seller_early',
            createdAt: DateTime.utc(2026, 1, 2),
            email: 'a@test.com',
          ),
        )
        ..seedPlayer(
          Player(
            playerId: 'seller-b',
            username: 'seller_late',
            createdAt: DateTime.utc(2026, 1, 3),
            email: 'b@test.com',
          ),
        );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          gameRepositoryProvider.overrideWithValue(games),
          orderRepositoryProvider.overrideWithValue(orders),
          executionRepositoryProvider.overrideWithValue(executions),
          commandRepositoryProvider.overrideWithValue(commands),
          playerRepositoryProvider.overrideWithValue(playerRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final data = await container.read(tradingViewDataProvider('tg-order').future);

      expect(data.tradeLogs.length, 2);
      expect(data.tradeLogs[0].price, 110);
      expect(data.tradeLogs[1].price, 100);
    });

    test('marketPrice is null when no trades and incomplete book', () async {
      final commands = InMemoryCommandRepository();
      final games = InMemoryGameRepository(commandRepository: commands);
      final orders = InMemoryOrderRepository();
      final executions = InMemoryExecutionRepository();
      final authRepo = InMemoryAuthRepository();
      authRepo.setSessionPlayerForTest(
        Player(
          playerId: 'viewer-1',
          username: 'viewer',
          createdAt: DateTime.utc(2026, 1, 1),
          email: 'v@test.com',
        ),
      );

      final start = DateTime.utc(2026, 3, 1, 12);
      games.seedGame(
        Game(
          gameId: 'tg-empty',
          gameName: 'Empty Book',
          gameDescription: 'D',
          gameCreatedAt: start,
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.casual,
          gameMaxPlayers: 4,
          joiningCode: 'EMPTY',
          endCondition: EndCondition.endless,
          gameState: GameState.tradingStarted,
          adminPlayerId: 'viewer-1',
          stateVersion: 1,
          updatedAt: start,
          startTime: start,
          lastTradedPrice: null,
        ),
      );
      games.seedGamePlayer(
        GamePlayer(
          gamesPlayersRowId: 'gp-e',
          mapGameId: 'tg-empty',
          mapPlayerId: 'viewer-1',
          lobbyStatus: LobbyStatus.playing,
          joinedAt: start,
          isAdmin: true,
          deltaCash: 0,
          deltaEnvelopes: 0,
          pnl: 0,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          gameRepositoryProvider.overrideWithValue(games),
          orderRepositoryProvider.overrideWithValue(orders),
          executionRepositoryProvider.overrideWithValue(executions),
          commandRepositoryProvider.overrideWithValue(commands),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final data =
          await container.read(tradingViewDataProvider('tg-empty').future);

      expect(data.marketPrice, isNull);
      expect(data.orderBookBids, isEmpty);
      expect(data.orderBookAsks, isEmpty);
    });

    test(
      'marketPrice is null with resting bid and ask but no trades '
      '(no bid/ask midpoint as market price)',
      () async {
      final commands = InMemoryCommandRepository();
      final games = InMemoryGameRepository(commandRepository: commands);
      final orders = InMemoryOrderRepository();
      final executions = InMemoryExecutionRepository();
      final authRepo = InMemoryAuthRepository();
      authRepo.setSessionPlayerForTest(
        Player(
          playerId: 'viewer-1',
          username: 'viewer',
          createdAt: DateTime.utc(2026, 1, 1),
          email: 'v@test.com',
        ),
      );

      final start = DateTime.utc(2026, 3, 1, 12);
      games.seedGame(
        Game(
          gameId: 'tg-book',
          gameName: 'Book Only',
          gameDescription: 'D',
          gameCreatedAt: start,
          gameSecurity: GameSecurity.public,
          isRanked: IsRanked.casual,
          gameMaxPlayers: 4,
          joiningCode: 'BOOK1',
          endCondition: EndCondition.endless,
          gameState: GameState.tradingStarted,
          adminPlayerId: 'viewer-1',
          stateVersion: 1,
          updatedAt: start,
          startTime: start,
          lastTradedPrice: null,
        ),
      );
      games.seedGamePlayer(
        GamePlayer(
          gamesPlayersRowId: 'gp-b',
          mapGameId: 'tg-book',
          mapPlayerId: 'viewer-1',
          lobbyStatus: LobbyStatus.playing,
          joinedAt: start,
          isAdmin: true,
          deltaCash: 0,
          deltaEnvelopes: 0,
          pnl: 0,
        ),
      );

      orders.seedOrders([
        Order(
          orderId: 'ask1',
          createdByPlayerId: 'other',
          gameId: 'tg-book',
          type: OrderType.limitSell,
          quantityInitial: 5,
          quantityCurrent: 5,
          pricePerStock: 202,
          status: OrderStatus.orderResting,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
        Order(
          orderId: 'bid1',
          createdByPlayerId: 'viewer-1',
          gameId: 'tg-book',
          type: OrderType.limitBuy,
          quantityInitial: 5,
          quantityCurrent: 5,
          pricePerStock: 198,
          status: OrderStatus.orderResting,
          orderCreatedAt: start,
          orderUpdatedAt: start,
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
          gameRepositoryProvider.overrideWithValue(games),
          orderRepositoryProvider.overrideWithValue(orders),
          executionRepositoryProvider.overrideWithValue(executions),
          commandRepositoryProvider.overrideWithValue(commands),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);
      final data =
          await container.read(tradingViewDataProvider('tg-book').future);

      expect(data.orderBookBids, isNotEmpty);
      expect(data.orderBookAsks, isNotEmpty);
      expect(data.marketPrice, isNull);
    });

    test('router-style trading override returns mock without hitting auth',
        () async {
      final container = ProviderContainer(
        overrides: [
          tradingViewDataProvider('g1').overrideWith(
            (ref) => Future.value(mockTradingScenarioForGameId('g1').data),
          ),
        ],
      );
      addTearDown(container.dispose);
      final data = await container.read(tradingViewDataProvider('g1').future);
      expect(data.gameTitle, 'Forex Masters');
    });

    test('golden minimal seed reproduces expectedViewData via adapter',
        () async {
      final harness = GoldenTradingMinimalHarness.create();
      addTearDown(harness.dispose);
      await harness.container.read(authControllerProvider.future);
      final data = await harness.container.read(
        tradingViewDataProvider(GoldenTradingMinimalSeed.gameId).future,
      );
      GoldenTradingMinimalSeed.assertMatchesExpected(data);
    });
  });
}
