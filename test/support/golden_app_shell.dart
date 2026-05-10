import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';

/// Minimal [GoRouter] so screens that call [GoRouter.of(context).go] in buttons
/// still pump under widget tests (INT1 goldens, results/profile/history).
GoRouter goldenShellRouter(Widget child) {
  Widget stub(String label) => Scaffold(body: Center(child: Text(label)));

  return GoRouter(
    initialLocation: '/__golden',
    routes: [
      GoRoute(path: '/__golden', builder: (_, _) => child),
      GoRoute(path: AppRoutes.auth, builder: (_, _) => stub('auth')),
      GoRoute(path: AppRoutes.home, builder: (_, _) => stub('home')),
      GoRoute(path: AppRoutes.create, builder: (_, _) => stub('create')),
      GoRoute(path: AppRoutes.orders, builder: (_, _) => stub('orders')),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => stub('profile')),
      GoRoute(path: AppRoutes.history, builder: (_, _) => stub('history')),
      GoRoute(
        path: '/game/:id/lobby',
        builder: (_, state) => stub('lobby-${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/game/:id/trading',
        builder: (_, state) => stub('trading-${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/game/:id/results',
        builder: (_, state) => stub('results-${state.pathParameters['id']}'),
      ),
    ],
  );
}

Widget goldenMaterialAppRouter({required Widget child}) {
  return MaterialApp.router(
    theme: buildAppTheme(),
    routerConfig: goldenShellRouter(child),
  );
}
