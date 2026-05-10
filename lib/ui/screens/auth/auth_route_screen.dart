import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../data/models/player.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/auth_tab_switcher.dart';
import 'auth_screen.dart';

/// Auth route body: wires [AuthScreen] to [authControllerProvider] and shows
/// errors via [SnackBar] (Phase 2B.1).
class AuthRouteScreen extends ConsumerWidget {
  const AuthRouteScreen({
    super.key,
    required this.initialTab,
  });

  final AuthTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Player?>>(authControllerProvider, (prev, next) {
      if (!next.hasError) return;
      final err = next.error;
      final text = err is AuthException ? err.message : '$err';
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(SnackBar(content: Text(text)));
    });

    return AuthScreen(
      key: ValueKey('auth-${initialTab.name}'),
      initialTab: initialTab,
      onLogIn: (sub) async {
        await ref.read(authControllerProvider.notifier).logIn(
              emailOrUsername: sub.identifier,
              password: sub.password,
            );
        if (!context.mounted) return;
        final s = ref.read(authControllerProvider);
        if (s.hasValue && s.value != null) {
          context.go(AppRoutes.home);
        }
      },
      onSignUp: (sub) async {
        await ref.read(authControllerProvider.notifier).signUp(
              email: sub.email,
              password: sub.password,
              username: sub.username,
            );
        if (!context.mounted) return;
        final s = ref.read(authControllerProvider);
        if (s.hasValue && s.value != null) {
          context.go(AppRoutes.home);
        }
      },
    );
  }
}
