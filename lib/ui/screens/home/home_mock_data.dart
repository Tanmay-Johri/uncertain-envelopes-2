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
    required this.playerInitials,
  });

  final String id;
  final String title;
  final String description;
  final GameStatusBadge status;
  final bool isPublic;
  final bool isJoined;
  final bool isAdmin;

  /// Single-letter initials for avatar stack (already uppercased).
  final List<String> playerInitials;
}

/// Hardcoded games mirroring the HTML mock variety (joined/public/admin).
const List<MockHomeGame> kMockHomeGames = [
  MockHomeGame(
    id: 'g1',
    title: 'Forex Masters',
    description:
        'High stakes currency trading simulation for advanced players. Real-time market volatility enabled.',
    status: GameStatusBadge.active,
    isPublic: true,
    isJoined: true,
    isAdmin: false,
    playerInitials: ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
  ),
  MockHomeGame(
    id: 'g2',
    title: 'Crypto Basics 101',
    description:
        'Beginner level cryptocurrency trading simulation. Learn the ropes without the risk.',
    status: GameStatusBadge.ready,
    isPublic: true,
    isJoined: true,
    isAdmin: true,
    playerInitials: ['J', 'K'],
  ),
  MockHomeGame(
    id: 'g3',
    title: 'Commodities Blitz',
    description: 'Fast-paced commodities market. Oil, Gold, and Wheat futures.',
    status: GameStatusBadge.joined,
    isPublic: true,
    isJoined: true,
    isAdmin: false,
    playerInitials: [],
  ),
  MockHomeGame(
    id: 'g4',
    title: 'Penny Stocks Derby',
    description: 'High risk, high reward. Small cap stock simulation.',
    status: GameStatusBadge.notJoined,
    isPublic: true,
    isJoined: false,
    isAdmin: false,
    playerInitials: [],
  ),
  MockHomeGame(
    id: 'g5',
    title: 'Private League Alpha',
    description: 'Invite-only ranked session.',
    status: GameStatusBadge.active,
    isPublic: false,
    isJoined: true,
    isAdmin: true,
    playerInitials: ['X'],
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
