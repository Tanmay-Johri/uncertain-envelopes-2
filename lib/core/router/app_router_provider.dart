import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/player.dart';
import '../../providers/auth_provider.dart';
import 'app_router.dart';

part 'app_router_provider.g.dart';

/// Initial location for [appRouterProvider]. Override in tests to deep-link.
@Riverpod(keepAlive: true)
String appRouterInitialLocation(Ref ref) => AppRoutes.home;

/// Production [GoRouter]: auth redirect + refresh on session changes (2B.1).
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AsyncValue<Player?>>(
    authControllerProvider,
    (AsyncValue<Player?>? previous, AsyncValue<Player?> next) {
      refresh.value++;
    },
  );
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return null;

    final onAuth = state.matchedLocation == AppRoutes.auth;
    final loggedIn = auth.hasValue && auth.valueOrNull != null;

    if (!loggedIn && !onAuth) {
      return AppRoutes.auth;
    }
    if (loggedIn && onAuth) {
      return AppRoutes.home;
    }
    return null;
  }

  return buildAppRouter(
    initialLocation: ref.read(appRouterInitialLocationProvider),
    refreshListenable: refresh,
    redirect: redirect,
  );
}
