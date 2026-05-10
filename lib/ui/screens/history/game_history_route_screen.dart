import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/view_data/game_history_view_data_provider.dart';
import '../../widgets/fetched_error_panel.dart';
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
        body: FetchedErrorPanel(
          message: '$e',
          onRetry: () => ref.invalidate(gameHistoryViewDataProvider),
        ),
      ),
      data: (entries) => GameHistoryScreen(entries: entries),
    );
  }
}
