import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';

import 'trading_view_data.dart';

/// Bid–ask midpoint for mock trading books where [gameTitle] matches a
/// dashboard that uses [_kMockOrderBookBids] / [_kMockOrderBookAsks].
///
/// Pending-orders stream C mirrors these titles loosely; titles with no mocked
/// book return `null` (hyphen in [NewOrderModal]).
double? mockBidAskMidpointForGameTitle(String gameTitle) {
  const withSampleBook = {
    'Forex Masters',
    'Crypto Basics 101',
    'Crypto Sim 2024',
  };
  if (!withSampleBook.contains(gameTitle)) return null;
  return computeBidAskMidpoint(_kMockOrderBookBids, _kMockOrderBookAsks);
}

/// Sample book from `admin_game_trading_dashboard_7` (prices / qty).
const _kMockOrderBookBids = <OrderBookLevel>[
  OrderBookLevel(price: 149.5, quantity: 50),
  OrderBookLevel(price: 149.2, quantity: 25),
  OrderBookLevel(price: 148.9, quantity: 100),
  OrderBookLevel(price: 148.5, quantity: 12),
  OrderBookLevel(price: 148.0, quantity: 5),
  OrderBookLevel(price: 147.5, quantity: 2),
  OrderBookLevel(price: 147.0, quantity: 1),
];

const _kMockOrderBookAsks = <OrderBookLevel>[
  OrderBookLevel(price: 150.5, quantity: 10),
  OrderBookLevel(price: 150.8, quantity: 40),
  OrderBookLevel(price: 151.0, quantity: 85),
  OrderBookLevel(price: 151.5, quantity: 120),
  OrderBookLevel(price: 152.0, quantity: 200),
  OrderBookLevel(price: 152.5, quantity: 250),
];

/// Elapsed session for axis rule (plan **B9**): 55 min → 10-minute divisions.
const _kMockChartSessionElapsed = Duration(minutes: 55);

/// Fixed UTC game start for mocks (Phase 2: Supabase `start_time`).
final _kMockGameStartedAtUtc = DateTime.utc(2026, 4, 10, 14, 0, 0);

/// Prices roughly follow `dashboard_7` SVG; times spread 0–55 min (mock executions).
final _kMockPriceHistory = List<PriceChartPoint>.generate(11, (i) {
  const prices = <double>[
    144,
    146,
    142,
    148,
    152,
    150,
    151,
    149,
    150.5,
    150.25,
    150.0,
  ];
  final minutes = (i * 55 / 10).round();
  return PriceChartPoint(
    timeElapsed: Duration(minutes: minutes),
    price: prices[i],
  );
});

/// Mock executed trades for the transaction log.
final _g1TradeLogs = <TradeLogEntry>[
  TradeLogEntry(
      sellerName: 'CryptoKing99', buyerName: 'Player1', quantity: 3, price: 149.50,
      tradedAt: _kMockGameStartedAtUtc.add(const Duration(minutes: 5))),
  TradeLogEntry(
      sellerName: 'Player2', buyerName: 'CryptoKing99', quantity: 5, price: 150.00,
      tradedAt: _kMockGameStartedAtUtc.add(const Duration(minutes: 12))),
  TradeLogEntry(
      sellerName: 'Player1', buyerName: 'Player2', quantity: 2, price: 148.90,
      tradedAt: _kMockGameStartedAtUtc.add(const Duration(minutes: 23))),
  TradeLogEntry(
      sellerName: 'CryptoKing99', buyerName: 'Player1', quantity: 7, price: 151.00,
      tradedAt: _kMockGameStartedAtUtc.add(const Duration(minutes: 41))),
];

final _g2TradeLogs = <TradeLogEntry>[
  TradeLogEntry(
      sellerName: 'TechTrader', buyerName: 'CryptoFan', quantity: 10, price: 150.00,
      tradedAt: _kMockGameStartedAtUtc.add(const Duration(minutes: 8))),
  TradeLogEntry(
      sellerName: 'CryptoFan', buyerName: 'TechTrader', quantity: 4, price: 150.80,
      tradedAt: _kMockGameStartedAtUtc.add(const Duration(minutes: 31))),
];

/// Mix of statuses for **Active orders** (C6). [createdAt] → **Created:** line.
final _g1PersonalOrders = <PersonalOrder>[
  PersonalOrder(
    id: 'po_g1_rest',
    side: PersonalOrderSide.buy,
    orderType: PersonalOrderType.limit,
    quantityInitial: 10,
    quantityCurrent: 7,
    limitPrice: 149.5,
    status: PersonalOrderStatus.resting,
    createdAt: DateTime.utc(2026, 4, 26, 10, 42),
  ),
  PersonalOrder(
    id: 'po_g1_q',
    side: PersonalOrderSide.sell,
    orderType: PersonalOrderType.market,
    quantityInitial: 5,
    quantityCurrent: 5,
    limitPrice: null,
    status: PersonalOrderStatus.inQueue,
    createdAt: DateTime.utc(2026, 4, 26, 10, 38),
  ),
  PersonalOrder(
    id: 'po_g1_proc',
    side: PersonalOrderSide.sell,
    orderType: PersonalOrderType.limit,
    quantityInitial: 3,
    quantityCurrent: 3,
    limitPrice: 151,
    status: PersonalOrderStatus.beingProcessed,
    createdAt: DateTime.utc(2026, 4, 26, 10, 35),
  ),
];

final _g2PersonalOrders = <PersonalOrder>[
  PersonalOrder(
    id: 'po_g2_rest',
    side: PersonalOrderSide.sell,
    orderType: PersonalOrderType.limit,
    quantityInitial: 8,
    quantityCurrent: 8,
    limitPrice: 150.8,
    status: PersonalOrderStatus.resting,
    createdAt: DateTime.utc(2026, 4, 26, 9, 15),
  ),
  PersonalOrder(
    id: 'po_g2_fill',
    side: PersonalOrderSide.buy,
    orderType: PersonalOrderType.limit,
    quantityInitial: 2,
    quantityCurrent: 0,
    limitPrice: 148,
    status: PersonalOrderStatus.filled,
    createdAt: DateTime.utc(2026, 4, 26, 9, 0),
  ),
];

/// Mock trading scenarios keyed by game id; aligns with [mockLobbyScenarioForGameId]
/// titles where possible.
GameTradingScenario mockTradingScenarioForGameId(String gameId) {
  switch (gameId) {
    case 'g1':
      return _g1PlayerTrading;
    case 'g2':
      return _g2AdminTrading;
    default:
      final matches = kMockHomeGames.where((g) => g.id == gameId);
      if (matches.isNotEmpty) {
        final home = matches.first;
        return GameTradingScenario(
          data: GameTradingViewData(
            gameTitle: home.title,
            description: home.description,
            isViewerAdmin: home.isAdmin,
            currentPlayerId: 'viewer',
            isTimed: true,
            tradingTimeRemaining: const Duration(minutes: 60),
            deltaCash: 0,
            deltaEnvelopes: 0,
            orderBookBids: const [],
            orderBookAsks: const [],
            marketPrice: null,
            priceHistory: const [],
            chartSessionElapsed: Duration.zero,
          ),
        );
      }
      return _g1PlayerTrading;
  }
}

final GameTradingScenario _g1PlayerTrading = GameTradingScenario(
  data: GameTradingViewData(
    gameTitle: 'Forex Masters',
    description:
        'High stakes currency trading simulation for advanced players. Real-time market volatility enabled.',
    isViewerAdmin: false,
    currentPlayerId: 'p_me',
    isTimed: true,
    tradingTimeRemaining: const Duration(minutes: 60),
    deltaCash: 12500,
    deltaEnvelopes: -45,
    orderBookBids: _kMockOrderBookBids,
    orderBookAsks: _kMockOrderBookAsks,
    marketPrice: 150,
    priceHistory: _kMockPriceHistory,
    chartSessionElapsed: _kMockChartSessionElapsed,
    gameStartedAtUtc: _kMockGameStartedAtUtc,
    personalOrders: _g1PersonalOrders,
    tradeLogs: _g1TradeLogs,
  ),
);

final GameTradingScenario _g2AdminTrading = GameTradingScenario(
  data: GameTradingViewData(
    gameTitle: 'Crypto Basics 101',
    description:
        'Beginner level cryptocurrency trading simulation. Learn the ropes without the risk.',
    isViewerAdmin: true,
    currentPlayerId: 'p_ad',
    isTimed: true,
    tradingTimeRemaining: const Duration(minutes: 60),
    deltaCash: 2400,
    deltaEnvelopes: -12,
    orderBookBids: _kMockOrderBookBids,
    orderBookAsks: _kMockOrderBookAsks,
    marketPrice: 150,
    priceHistory: _kMockPriceHistory,
    chartSessionElapsed: _kMockChartSessionElapsed,
    gameStartedAtUtc: _kMockGameStartedAtUtc,
    personalOrders: _g2PersonalOrders,
    tradeLogs: _g2TradeLogs,
  ),
);
