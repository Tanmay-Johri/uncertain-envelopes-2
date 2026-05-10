import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/view_data/game_history_view_data_provider.dart';
import 'game_history_screen.dart';

/// Route body: loads [gameHistoryViewDataProvider] (Phase 2B.9).
class GameHistoryRouteScreen extends ConsumerWidget {
  const GameHistoryRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameHistoryViewDataProvider);
    return async.when(
      loading: () => const Scaffold(
        key: ValueKey('game-history-route-loading'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        key: const ValueKey('game-history-route-error'),
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
      data: (entries) => GameHistoryScreen(entries: entries),
    );
  }
}
