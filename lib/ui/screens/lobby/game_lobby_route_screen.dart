import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/view_data/lobby_view_data_provider.dart';
import '../../widgets/fetched_error_panel.dart';
import 'game_lobby_screen.dart';

/// Shell route body: loads [lobbyViewDataProvider] and wires lobby actions to
/// [commandRepositoryProvider] (Phase 2B.4).
class GameLobbyRouteScreen extends ConsumerWidget {
  const GameLobbyRouteScreen({super.key, required this.gameId});

  final String gameId;

  Future<void> _runCommand(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lobbyViewDataProvider(gameId));
    return async.when(
      loading: () => const Scaffold(
        key: ValueKey('game-lobby-loading'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        key: const ValueKey('game-lobby-error'),
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
          onRetry: () => ref.invalidate(lobbyViewDataProvider(gameId)),
        ),
      ),
      data: (scenario) {
        final viewer = ref.read(authControllerProvider).valueOrNull;
        final playerId = viewer?.playerId ?? scenario.currentPlayerId;
        final cmds = ref.read(commandRepositoryProvider);
        return GameLobbyScreen(
          data: scenario.data,
          phase: scenario.phase,
          currentPlayerId: scenario.currentPlayerId,
          isViewerAdmin: scenario.isViewerAdmin,
          onStartGame: () => _runCommand(context, ref, () async {
            await cmds.submitStartGame(gameId: gameId, adminPlayerId: playerId);
          }),
          onEndGame: () => _runCommand(context, ref, () async {
            await cmds.submitEndTrading(
              gameId: gameId,
              adminPlayerId: playerId,
            );
          }),
          onEnterGame: () => context.go(AppRoutes.gameTrading(gameId)),
          onJoinGame: () => _runCommand(context, ref, () async {
            await cmds.submitJoinGame(gameId: gameId, playerId: playerId);
          }),
          onLeaveGame: () => _runCommand(context, ref, () async {
            await cmds.submitLeaveGame(gameId: gameId, playerId: playerId);
          }),
          onKickPlayer: (targetPlayerId) => _runCommand(context, ref, () async {
            await cmds.submitKickPlayer(
              gameId: gameId,
              adminPlayerId: playerId,
              targetPlayerId: targetPlayerId,
            );
          }),
        );
      },
    );
  }
}
