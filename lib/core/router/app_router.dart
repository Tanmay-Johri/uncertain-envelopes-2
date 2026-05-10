import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/screens/_placeholder_screen.dart';
import '../../ui/screens/auth/auth_route_screen.dart';
import '../../ui/screens/history/game_history_mock_data.dart';
import '../../ui/screens/history/game_history_screen.dart';
import '../../ui/screens/profile/profile_mock_data.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/profile/profile_view_data.dart';
import '../../ui/screens/create_game/create_game_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/orders/pending_orders_screen.dart';
import '../../ui/screens/lobby/game_lobby_route_screen.dart';
import '../../ui/screens/results/game_results_mock_route_host.dart';
import '../../ui/screens/trading/game_trading_screen.dart';
import '../../ui/screens/trading/trading_mock_data.dart';
import '../../ui/widgets/app_shell.dart';
import '../../ui/widgets/auth_tab_switcher.dart';
import '../../ui/widgets/game_realtime_session_scope.dart';

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
///
/// When [redirect] and [refreshListenable] are omitted (the default), no
/// auth redirect runs — used by router unit tests. Production uses
/// [appRouterProvider] which passes auth-aware values.
GoRouter buildAppRouter({
  String initialLocation = AppRoutes.home,
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: redirect,
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
          return AuthRouteScreen(initialTab: initialTab);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, _) => ProfileScreen(
          data: mockProfileViewDataDefault(),
          onGameHistoryTap: () => context.go(AppRoutes.history),
          onSignOut: () {},
          onDeleteAccount: () {},
          onUsernameCommit: (lowercaseUsername) async {
            if (lowercaseUsername == 'taken') {
              return ProfileUsernameSubmitResult.taken;
            }
            return ProfileUsernameSubmitResult.success;
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (context, _) =>
            GameHistoryScreen(entries: kMockGameHistory()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) return child;
          return GameRealtimeSessionScope(gameId: id, child: child);
        },
        routes: [
          GoRoute(
            path: '/game/:id/lobby',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return GameLobbyRouteScreen(gameId: id);
            },
          ),
          GoRoute(
            path: '/game/:id/trading',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              final scenario = mockTradingScenarioForGameId(id);
              return GameTradingScreen(
                gameId: id,
                data: scenario.data,
                onEndGameFromMenu: () {},
                onAddTime: (_) {},
              );
            },
          ),
          GoRoute(
            path: '/game/:id/results',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return GameResultsMockRouteHost(gameId: id);
            },
          ),
        ],
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
                builder: (context, _) => const CreateGameScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (context, _) => const PendingOrdersScreen(),
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
