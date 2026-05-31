import '../../widgets/status_badge.dart';

/// One row in the home / lobby discovery list (Stream C mock).
class MockHomeGame {
  const MockHomeGame({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.isPublic,
    required this.isJoined,
    required this.isAdmin,
    required this.playerCount,
    required this.maxPlayers,
    this.openEnvelopeResults = false,
  });

  final String id;
  final String title;
  final String description;
  final GameStatusBadge status;
  final bool isPublic;
  final bool isJoined;
  final bool isAdmin;

  /// When true, home opens results/envelope route instead of lobby.
  final bool openEnvelopeResults;

  /// Current number of players in the room.
  final int playerCount;

  /// Maximum players allowed in the room (capacity).
  final int maxPlayers;
}

/// Hardcoded games mirroring the HTML mock variety (joined/public/admin).
const List<MockHomeGame> kMockHomeGames = [
  MockHomeGame(
    id: 'g1',
    title: 'Forex Masters',
    description:
        'High stakes currency trading simulation for advanced players. Real-time market volatility enabled.',
    status: GameStatusBadge.playing,
    isPublic: true,
    isJoined: true,
    isAdmin: false,
    playerCount: 7,
    maxPlayers: 12,
  ),
  MockHomeGame(
    id: 'g2',
    title: 'Crypto Basics 101',
    description:
        'Beginner level cryptocurrency trading simulation. Learn the ropes without the risk.',
    status: GameStatusBadge.joined,
    isPublic: true,
    isJoined: true,
    isAdmin: true,
    playerCount: 2,
    maxPlayers: 8,
  ),
  MockHomeGame(
    id: 'g3',
    title: 'Commodities Blitz',
    description: 'Fast-paced commodities market. Oil, Gold, and Wheat futures.',
    status: GameStatusBadge.joined,
    isPublic: true,
    isJoined: true,
    isAdmin: false,
    playerCount: 0,
    maxPlayers: 12,
  ),
  MockHomeGame(
    id: 'g4',
    title: 'Penny Stocks Derby',
    description: 'High risk, high reward. Small cap stock simulation.',
    status: GameStatusBadge.notJoined,
    isPublic: true,
    isJoined: false,
    isAdmin: false,
    playerCount: 0,
    maxPlayers: 20,
  ),
  MockHomeGame(
    id: 'g5',
    title: 'Private League Alpha',
    description: 'Invite-only ranked session.',
    status: GameStatusBadge.playing,
    isPublic: false,
    isJoined: true,
    isAdmin: true,
    playerCount: 1,
    maxPlayers: 8,
  ),
];

bool mockHomeGamePassesFilters(
  MockHomeGame g, {
  required bool joinedTab,
  required bool adminOnly,
}) {
  if (joinedTab) {
    if (!g.isJoined) return false;
  } else {
    if (!g.isPublic) return false;
  }
  if (adminOnly && !g.isAdmin) return false;
  return true;
}
