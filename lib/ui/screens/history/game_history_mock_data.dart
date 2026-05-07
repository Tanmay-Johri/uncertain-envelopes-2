import 'game_history_view_data.dart';

/// Mock game history aligned with
/// `design-uncertain-envelopes-2/admin_game_trading_dashboard_6/code.html`.
List<GameHistoryEntry> kMockGameHistory() => [
      GameHistoryEntry(
        id: 'gh-1',
        title: 'Alpha Market',
        description: 'Forex volatility simulation',
        viewerPnl: 240,
        securityType: 'Public',
        isRanked: true,
        adminName: 'MasterTrader',
        envelopePriceUsd: 12.50,
        startedAt: DateTime.utc(2024, 10, 24, 14, 30),
        endedAt: DateTime.utc(2024, 10, 24, 16, 0),
        playerResults: const [
          GameHistoryPlayerResult(
            playerId: 'p1',
            displayName: 'Player1',
            pnl: 100,
          ),
          GameHistoryPlayerResult(
            playerId: 'p2',
            displayName: 'Player2',
            pnl: -20,
          ),
          GameHistoryPlayerResult(
            playerId: 'p3',
            displayName: 'CryptoKing99',
            pnl: 160,
          ),
        ],
      ),
      GameHistoryEntry(
        id: 'gh-2',
        title: 'Beta Indices',
        description: 'S&P 500 futures tracking',
        viewerPnl: -50,
        securityType: 'Public',
        isRanked: false,
        adminName: 'MasterTrader',
        envelopePriceUsd: 8.00,
        startedAt: DateTime.utc(2024, 10, 20, 10, 0),
        endedAt: DateTime.utc(2024, 10, 20, 11, 45),
        playerResults: const [
          GameHistoryPlayerResult(
            playerId: 'p1',
            displayName: 'Player1',
            pnl: 80,
          ),
          GameHistoryPlayerResult(
            playerId: 'p4',
            displayName: 'IndexWatcher',
            pnl: -50,
          ),
          GameHistoryPlayerResult(
            playerId: 'p5',
            displayName: 'FuturesFan',
            pnl: -30,
          ),
        ],
      ),
      GameHistoryEntry(
        id: 'gh-3',
        title: 'Commodity Rush',
        description: 'Gold vs Oil spread',
        viewerPnl: 85,
        securityType: 'Private',
        isRanked: true,
        adminName: 'MasterTrader',
        envelopePriceUsd: 15.00,
        startedAt: DateTime.utc(2024, 10, 15, 9, 0),
        endedAt: DateTime.utc(2024, 10, 15, 10, 30),
        playerResults: const [
          GameHistoryPlayerResult(
            playerId: 'p3',
            displayName: 'CryptoKing99',
            pnl: 200,
          ),
          GameHistoryPlayerResult(
            playerId: 'p6',
            displayName: 'GoldBug',
            pnl: 85,
          ),
          GameHistoryPlayerResult(
            playerId: 'p7',
            displayName: 'OilBaron',
            pnl: -115,
          ),
        ],
      ),
      GameHistoryEntry(
        id: 'gh-4',
        title: 'Crypto Swing',
        description: 'BTC/ETH heavy leverage',
        viewerPnl: 1200,
        securityType: 'Public',
        isRanked: true,
        adminName: 'MasterTrader',
        envelopePriceUsd: 95.00,
        startedAt: DateTime.utc(2024, 10, 10, 16, 45),
        endedAt: DateTime.utc(2024, 10, 10, 18, 15),
        playerResults: const [
          GameHistoryPlayerResult(
            playerId: 'p8',
            displayName: 'SatoshiJr',
            pnl: 1200,
          ),
          GameHistoryPlayerResult(
            playerId: 'p9',
            displayName: 'EtherDreamer',
            pnl: 340,
          ),
          GameHistoryPlayerResult(
            playerId: 'p2',
            displayName: 'Player2',
            pnl: -440,
          ),
        ],
      ),
      GameHistoryEntry(
        id: 'gh-5',
        title: 'Tech Bubble',
        description: 'Nasdaq volatility options',
        viewerPnl: -120,
        securityType: 'Private',
        isRanked: false,
        adminName: 'MasterTrader',
        envelopePriceUsd: 22.50,
        startedAt: DateTime.utc(2024, 10, 5, 11, 15),
        endedAt: DateTime.utc(2024, 10, 5, 13, 0),
        playerResults: const [
          GameHistoryPlayerResult(
            playerId: 'p10',
            displayName: 'NasdaqNerd',
            pnl: 300,
          ),
          GameHistoryPlayerResult(
            playerId: 'p11',
            displayName: 'BubbleWatcher',
            pnl: -120,
          ),
          GameHistoryPlayerResult(
            playerId: 'p12',
            displayName: 'TechSkeptic',
            pnl: -180,
          ),
        ],
      ),
    ];
