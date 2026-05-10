import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/player_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/player_repository_provider.dart';
import '../../../providers/view_data/profile_view_data_provider.dart';
import 'profile_screen.dart';
import 'profile_view_data.dart';

/// Shell route body: loads [profileViewDataProvider] and wires profile
/// actions to repositories (Phase 2B.7).
class ProfileRouteScreen extends ConsumerWidget {
  const ProfileRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileViewDataProvider);
    return async.when(
      loading: () => const Scaffold(
        key: ValueKey('profile-route-loading'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        key: const ValueKey('profile-route-error'),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: BackButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$e',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ),
        ),
      ),
      data: (data) {
        return ProfileScreen(
          data: data,
          onUsernameCommit: (lowercaseUsername) async {
            final viewer = ref.read(authControllerProvider).valueOrNull;
            if (viewer == null) {
              return ProfileUsernameSubmitResult.success;
            }
            try {
              final updated = await ref
                  .read(playerRepositoryProvider)
                  .updateUsername(
                    playerId: viewer.playerId,
                    newUsername: lowercaseUsername,
                  );
              await ref
                  .read(authControllerProvider.notifier)
                  .adoptUpdatedProfile(updated);
              return ProfileUsernameSubmitResult.success;
            } on UsernameAlreadyInUseException {
              return ProfileUsernameSubmitResult.taken;
            }
          },
          onSignOut: () {
            unawaited((() async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              context.go(AppRoutes.auth);
            })());
          },
          onGameHistoryTap: () => context.go(AppRoutes.history),
          onDeleteAccount: () {
            unawaited((() async {
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (!context.mounted) return;
              context.go(AppRoutes.auth);
            })());
          },
        );
      },
    );
  }
}
