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
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/providers/command_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/trading_repository_providers.dart';
import 'package:uncertain_envelopes_2/providers/view_data/trading_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_mock_data.dart';

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
  });
}
