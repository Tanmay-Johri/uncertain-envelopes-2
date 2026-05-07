import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';

import 'lobby_view_data.dart';

/// Mock lobby scenarios keyed by [MockHomeGame.id] where we have bespoke
/// fixtures; unknown ids fall back to a generic trading lobby.
GameLobbyScenario mockLobbyScenarioForGameId(String gameId) {
  switch (gameId) {
    case 'g1pre':
      return _g1PlayerPreStart;
    case 'g2':
      return _g2AdminPreStart;
    case 'g1':
      return _g1PlayerTrading;
    default:
      final matches = kMockHomeGames.where((g) => g.id == gameId);
      if (matches.isNotEmpty) {
        final home = matches.first;
        return GameLobbyScenario(
          data: _dataFromHomeGame(home),
          phase: GameLobbyPhase.trading,
          currentPlayerId: 'viewer',
          isViewerAdmin: home.isAdmin,
        );
      }
      return _g1PlayerTrading;
  }
}

GameLobbyViewData _dataFromHomeGame(MockHomeGame g) {
  final initialsList =
      g.playerInitials.isEmpty ? <String>['?'] : g.playerInitials;
  final n = initialsList.length.clamp(1, 8);
  final players = List<LobbyPlayerView>.generate(n, (i) {
    final isAdmin = g.isAdmin && i == 0;
    return LobbyPlayerView(
      id: 'p$i',
      username: isAdmin ? 'HostUser' : 'Player ${i + 1}',
      initials: initialsList[i],
      isGameAdmin: isAdmin,
    );
  });
  return GameLobbyViewData(
    gameTitle: g.title,
    description: g.description,
    joiningCodeRaw: _codeForId(g.id),
    isPublic: g.isPublic,
    isRanked: true,
    maxPlayers: g.maxPlayers,
    players: players,
    isTimed: true,
    tradingTimeRemaining: const Duration(minutes: 60),
  );
}

String _codeForId(String id) {
  final pad = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  return '${pad}ABCDE'.substring(0, 5);
}

/// Forex Masters — non-admin, trading phase (matches first HTML mock).
final GameLobbyScenario _g1PlayerTrading = GameLobbyScenario(
  data: GameLobbyViewData(
    gameTitle: 'Forex Masters',
    description:
        'High stakes currency trading simulation for advanced players. Real-time market volatility enabled.',
    joiningCodeRaw: 'V8JAJ',
    isPublic: true,
    isRanked: true,
    maxPlayers: 8,
    players: const [
      LobbyPlayerView(
        id: 'p_ad',
        username: 'AdminUser',
        initials: 'AD',
        isGameAdmin: true,
      ),
      LobbyPlayerView(
        id: 'p_js',
        username: 'JohnSmith',
        initials: 'JS',
        isGameAdmin: false,
      ),
      LobbyPlayerView(
        id: 'p_tk',
        username: 'TraderKing',
        initials: 'TK',
        isGameAdmin: false,
      ),
      LobbyPlayerView(
        id: 'p_me',
        username: 'CryptoWhale',
        initials: 'ME',
        isGameAdmin: false,
      ),
    ],
    isTimed: true,
    tradingTimeRemaining: Duration(minutes: 60),
  ),
  phase: GameLobbyPhase.trading,
  currentPlayerId: 'p_me',
  isViewerAdmin: false,
);

/// Forex Masters — same roster as [_g1PlayerTrading] but lobby not started yet;
/// viewer is a joined non-admin (Leave Game).
final GameLobbyScenario _g1PlayerPreStart = GameLobbyScenario(
  data: _g1PlayerTrading.data,
  phase: GameLobbyPhase.preStart,
  currentPlayerId: _g1PlayerTrading.currentPlayerId,
  isViewerAdmin: false,
);

/// Crypto Basics — viewer is admin, pre-start (second HTML mock).
final GameLobbyScenario _g2AdminPreStart = GameLobbyScenario(
  data: GameLobbyViewData(
    gameTitle: 'Crypto Basics 101',
    description:
        'Beginner level cryptocurrency trading simulation. Learn the ropes without the risk.',
    joiningCodeRaw: 'Z9K2M',
    isPublic: true,
    isRanked: true,
    maxPlayers: 8,
    players: const [
      LobbyPlayerView(
        id: 'p_ad',
        username: 'AdminUser',
        initials: 'AD',
        isGameAdmin: true,
      ),
      LobbyPlayerView(
        id: 'p_js',
        username: 'JohnSmith',
        initials: 'JS',
        isGameAdmin: false,
      ),
      LobbyPlayerView(
        id: 'p_tk',
        username: 'TraderKing',
        initials: 'TK',
        isGameAdmin: false,
      ),
      LobbyPlayerView(
        id: 'p_cw',
        username: 'CryptoWhale',
        initials: 'CW',
        isGameAdmin: false,
      ),
    ],
    isTimed: true,
    tradingTimeRemaining: Duration(minutes: 60),
  ),
  phase: GameLobbyPhase.preStart,
  currentPlayerId: 'p_ad',
  isViewerAdmin: true,
);
