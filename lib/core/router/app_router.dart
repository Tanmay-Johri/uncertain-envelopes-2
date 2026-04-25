import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/screens/_placeholder_screen.dart';
import '../../ui/screens/auth/auth_screen.dart';
import '../../ui/screens/create_game/create_game_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/lobby/game_lobby_screen.dart';
import '../../ui/screens/lobby/lobby_mock_data.dart';
import '../../ui/widgets/app_shell.dart';
import '../../ui/widgets/auth_tab_switcher.dart';

/// Route paths for the whole app. Centralising them avoids typo-style
/// navigation bugs. Parametric routes expose helpers instead of raw
/// patterns.
abstract final class AppRoutes {
  static const auth = '/auth';
  static const home = '/home';
  static const create = '/create';
  static const orders = '/orders';
  static const profile = '/profile';
  static const history = '/history';

  static String gameLobby(String id) => '/game/$id/lobby';
  static String gameTrading(String id) => '/game/$id/trading';
  static String gameResults(String id) => '/game/$id/results';
}

/// Index of each bottom-nav destination inside the
/// [StatefulShellRoute]. Keep this aligned with [AppNavDestination].
abstract final class _ShellIndex {
  static const home = 0;
  static const create = 1;
  static const orders = 2;
}

/// Builds the top-level GoRouter instance.
///
/// [initialLocation] is exposed so tests can deep-link to any route
/// without having to wire up a Flutter engine navigator.
GoRouter buildAppRouter({String initialLocation = AppRoutes.home}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.auth,
        builder: (_, state) {
          // Allow /auth?tab=signup to deep-link to the sign-up tab.
          // We tie the initial tab to a ValueKey so a fresh
          // AuthScreen State is built whenever the query param
          // changes — otherwise didUpdateWidget would be needed to
          // re-apply initialTab.
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = tabParam == 'signup'
              ? AuthTab.signUp
              : AuthTab.logIn;
          return AuthScreen(
            key: ValueKey('auth-${initialTab.name}'),
            initialTab: initialTab,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) =>
            const PlaceholderScreen(routeName: 'PROFILE'),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) =>
            const PlaceholderScreen(routeName: 'HISTORY'),
      ),
      GoRoute(
        path: '/game/:id/lobby',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          final scenario = mockLobbyScenarioForGameId(id);
          return GameLobbyScreen(
            data: scenario.data,
            phase: scenario.phase,
            currentPlayerId: scenario.currentPlayerId,
            isViewerAdmin: scenario.isViewerAdmin,
            onStartGame: () {},
            onEndGame: () {},
            onEnterGame: () {},
            onJoinGame: () {},
            onLeaveGame: () {},
            onKickPlayer: (_) {},
          );
        },
      ),
      GoRoute(
        path: '/game/:id/trading',
        builder: (_, state) => PlaceholderScreen(
          routeName: 'GAME TRADING',
          subtitle: 'id=${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: '/game/:id/results',
        builder: (_, state) => PlaceholderScreen(
          routeName: 'GAME RESULTS',
          subtitle: 'id=${state.pathParameters['id']}',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) =>
                navigationShell.goBranch(index, initialLocation: true),
            onAccountTap: () => context.go(AppRoutes.profile),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, _) => HomeScreen(
                  onOpenGame: (id) =>
                      GoRouter.of(context).go(AppRoutes.gameLobby(id)),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.create,
                builder: (_, __) => const CreateGameScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, __) =>
                    const PlaceholderScreen(routeName: 'ORDERS'),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => PlaceholderScreen(
      routeName: 'NOT FOUND',
      subtitle: state.uri.toString(),
    ),
  );
}

/// Map a shell branch index to its destination enum for logging/tests.
AppNavDestination shellIndexToDestination(int index) {
  switch (index) {
    case _ShellIndex.home:
      return AppNavDestination.home;
    case _ShellIndex.create:
      return AppNavDestination.create;
    case _ShellIndex.orders:
      return AppNavDestination.orders;
    default:
      throw ArgumentError('Invalid shell index: $index');
  }
}
