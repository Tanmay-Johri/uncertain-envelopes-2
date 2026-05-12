import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/enums/lobby_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_status.dart';
import 'package:uncertain_envelopes_2/data/enums/order_type.dart';
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
import 'package:uncertain_envelopes_2/providers/clock_provider.dart';
import 'package:uncertain_envelopes_2/providers/command_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/game_repository_provider.dart';
import 'package:uncertain_envelopes_2/providers/trading_repository_providers.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_view_data.dart';

/// Fixed instant for clock + tick stream (chart elapsed = 0 vs [tStart]).
final DateTime goldenTradingTStart = DateTime.utc(2026, 5, 1, 12);

/// Holds a [ProviderContainer] plus a tick stream kept open for Riverpod
/// (a single-event stream can complete and dispose async providers mid-load).
final class GoldenTradingMinimalHarness {
  GoldenTradingMinimalHarness._(this.container, this._tickStream);

  final ProviderContainer container;
  final StreamController<DateTime> _tickStream;

  static GoldenTradingMinimalHarness create() {
    final commands = InMemoryCommandRepository();
    final games = InMemoryGameRepository(commandRepository: commands);
    final orders = InMemoryOrderRepository();
    final executions = InMemoryExecutionRepository();
    final authRepo = InMemoryAuthRepository();
    authRepo.setSessionPlayerForTest(
      Player(
        playerId: 'p-golden',
        username: 'goldenuser',
        createdAt: DateTime.utc(2026, 1, 1),
        email: 'g@test.com',
      ),
    );

    final t0 = goldenTradingTStart;
    const gid = GoldenTradingMinimalSeed.gameId;
    games.seedGame(
      Game(
        gameId: gid,
        gameName: 'Golden Co',
        gameDescription: 'd',
        gameCreatedAt: DateTime.utc(2026, 4, 1, 10),
        gameSecurity: GameSecurity.public,
        isRanked: IsRanked.casual,
        gameMaxPlayers: 8,
        joiningCode: 'GLDMN',
        endCondition: EndCondition.endless,
        gameState: GameState.tradingStarted,
        adminPlayerId: 'p-admin',
        stateVersion: 1,
        updatedAt: DateTime.utc(2026, 4, 1, 11),
        startTime: t0,
        lastTradedPrice: null,
      ),
    );
    games.seedGamePlayer(
      GamePlayer(
        gamesPlayersRowId: 'gp-admin',
        mapGameId: gid,
        mapPlayerId: 'p-admin',
        lobbyStatus: LobbyStatus.playing,
        joinedAt: DateTime.utc(2026, 4, 1, 10),
        isAdmin: true,
        deltaCash: 0,
        deltaEnvelopes: 0,
        pnl: 0,
      ),
    );
    games.seedGamePlayer(
      GamePlayer(
        gamesPlayersRowId: 'gp-golden',
        mapGameId: gid,
        mapPlayerId: 'p-golden',
        lobbyStatus: LobbyStatus.playing,
        joinedAt: DateTime.utc(2026, 4, 1, 10, 1),
        isAdmin: false,
        deltaCash: 100,
        deltaEnvelopes: -1,
        pnl: 0,
      ),
    );

    orders.seedOrders([
      Order(
        orderId: 'o-bid-other',
        createdByPlayerId: 'p-admin',
        gameId: gid,
        type: OrderType.limitBuy,
        quantityInitial: 1,
        quantityCurrent: 1,
        pricePerStock: 10,
        status: OrderStatus.orderResting,
        orderCreatedAt: t0,
        orderUpdatedAt: t0,
      ),
      Order(
        orderId: 'o-ask-other',
        createdByPlayerId: 'p-admin',
        gameId: gid,
        type: OrderType.limitSell,
        quantityInitial: 2,
        quantityCurrent: 2,
        pricePerStock: 12,
        status: OrderStatus.orderResting,
        orderCreatedAt: t0,
        orderUpdatedAt: t0,
      ),
    ]);

    final tickStream = StreamController<DateTime>.broadcast();
    tickStream.add(goldenTradingTStart);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        gameRepositoryProvider.overrideWithValue(games),
        orderRepositoryProvider.overrideWithValue(orders),
        executionRepositoryProvider.overrideWithValue(executions),
        commandRepositoryProvider.overrideWithValue(commands),
        clockProvider.overrideWith((_) => () => goldenTradingTStart),
        timerTickStreamProvider.overrideWith((_) => tickStream.stream),
      ],
    );
    return GoldenTradingMinimalHarness._(container, tickStream);
  }

  /// Closes the tick stream, then disposes the container.
  void dispose() {
    _tickStream.close();
    container.dispose();
  }
}

/// Minimal trading snapshot used for **mock-vs-adapter pixel parity** goldens.
///
/// Chosen so [tradingViewDataProvider] can reproduce it from in-memory repos:
/// - No executions and no `last_traded_price` → [marketPrice] is `null`
///   (hyphen in UI); bid/ask book still populated for the order book widget.
/// - [EndCondition.endless] → no [CountdownTimer] (avoids periodic timer drift
///   in golden captures).
abstract final class GoldenTradingMinimalSeed {
  static const String gameId = 'g-golden-min';

  /// Canonical [GameTradingViewData] for both the direct mock pump and the
  /// provider-driven pump after seeding [GoldenTradingMinimalHarness.create].
  static GameTradingViewData get expectedViewData => GameTradingViewData(
        gameTitle: 'Golden Co',
        description: 'd',
        isViewerAdmin: false,
        currentPlayerId: 'p-golden',
        isTimed: false,
        tradingTimeRemaining: null,
        deltaCash: 100,
        deltaEnvelopes: -1,
        orderBookBids: const [OrderBookLevel(price: 10, quantity: 1)],
        orderBookAsks: const [OrderBookLevel(price: 12, quantity: 2)],
        marketPrice: null,
        priceHistory: const [],
        chartSessionElapsed: Duration.zero,
        personalOrders: const [],
        tradeLogs: const [],
        gameStartedAtUtc: goldenTradingTStart,
        tradingDeadlineUtc: null,
      );

  /// Asserts [actual] matches [expectedViewData] field-for-field (lists deep).
  static void assertMatchesExpected(GameTradingViewData actual) {
    final expected = expectedViewData;
    expect(actual.gameTitle, expected.gameTitle);
    expect(actual.description, expected.description);
    expect(actual.isViewerAdmin, expected.isViewerAdmin);
    expect(actual.currentPlayerId, expected.currentPlayerId);
    expect(actual.isTimed, expected.isTimed);
    expect(actual.tradingTimeRemaining, expected.tradingTimeRemaining);
    expect(actual.tradingDeadlineUtc, expected.tradingDeadlineUtc);
    expect(actual.deltaCash, expected.deltaCash);
    expect(actual.deltaEnvelopes, expected.deltaEnvelopes);
    expect(actual.marketPrice, expected.marketPrice);
    expect(actual.chartSessionElapsed, expected.chartSessionElapsed);
    expect(actual.gameStartedAtUtc, expected.gameStartedAtUtc);
    expect(actual.priceHistory, expected.priceHistory);
    expect(actual.personalOrders, expected.personalOrders);
    expect(actual.tradeLogs, expected.tradeLogs);
    _expectOrderBookLevels(actual.orderBookBids, expected.orderBookBids);
    _expectOrderBookLevels(actual.orderBookAsks, expected.orderBookAsks);
  }

  static void _expectOrderBookLevels(
    List<OrderBookLevel> a,
    List<OrderBookLevel> b,
  ) {
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].price, b[i].price);
      expect(a[i].quantity, b[i].quantity);
    }
  }
}
