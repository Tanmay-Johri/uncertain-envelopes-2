import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';

import 'trading_view_data.dart';

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
  ),
);
