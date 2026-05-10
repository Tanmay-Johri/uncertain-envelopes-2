import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/view_data/results_view_data_provider.dart';
import 'game_results_screen.dart';

/// Shell route body: loads [resultsViewDataProvider] and wires results actions
/// to [commandRepositoryProvider] (Phase 2B.6).
class GameResultsRouteScreen extends ConsumerWidget {
  const GameResultsRouteScreen({super.key, required this.gameId});

  final String gameId;

  Future<void> _runCommand(
    BuildContext context,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  String _commandPlayerId(WidgetRef ref, String? viewerId, String? highlightId) {
    final admin = ref.read(currentGameProvider(gameId)).valueOrNull?.game.adminPlayerId;
    return viewerId ?? highlightId ?? admin ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(resultsViewDataProvider(gameId));
    return async.when(
      loading: () => const Scaffold(
        key: ValueKey('game-results-loading'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        key: const ValueKey('game-results-error'),
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
        final viewer = ref.read(authControllerProvider).valueOrNull;
        final playerId = _commandPlayerId(ref, viewer?.playerId, data.highlightPlayerId);
        final cmds = ref.read(commandRepositoryProvider);

        return GameResultsScreen(
          gameId: gameId,
          data: data,
          onUpdateEnvelopePrice: data.isViewerAdmin && !data.gameEnded
              ? (usd) async {
                  if (usd == null) {
                    await ref.read(currentGameProvider(gameId).notifier).refresh();
                    return;
                  }
                  await cmds.submitSetEnvelopePrice(
                    gameId: gameId,
                    adminPlayerId: playerId,
                    envelopePrice: usd,
                  );
                  await ref.read(currentGameProvider(gameId).notifier).refresh();
                }
              : null,
          pollCommittedEnvelopePrice: data.isViewerAdmin && !data.gameEnded
              ? () async {
                  await ref.read(currentGameProvider(gameId).notifier).refresh();
                  return ref.read(currentGameProvider(gameId)).valueOrNull?.game.envelopePrice;
                }
              : null,
          onEndGame: data.gameEnded
              ? null
              : ({required bool discardBecauseNoPrice}) {
                  unawaited(
                    _runCommand(context, () async {
                      if (discardBecauseNoPrice) {
                        await cmds.submitDiscardGame(
                          gameId: gameId,
                          adminPlayerId: playerId,
                        );
                      } else {
                        await cmds.submitFinaliseGame(
                          gameId: gameId,
                          adminPlayerId: playerId,
                        );
                      }
                      await ref.read(currentGameProvider(gameId).notifier).refresh();
                    }),
                  );
                },
        );
      },
    );
  }
}
