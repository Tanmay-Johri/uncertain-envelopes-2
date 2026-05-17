import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/game_flow.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/enums/game_state.dart';
import '../../../data/models/game_session_state.dart';
import '../../../data/repositories/command_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/view_data/home_view_data_provider.dart';
import '../../../providers/view_data/lobby_view_data_provider.dart'
    show LobbyViewDataException, lobbyViewDataProvider;
import '../../widgets/async_route_loading_body.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/fetched_error_panel.dart';
import 'game_lobby_screen.dart';
import 'lobby_view_data.dart';

/// Friendly copy for lobby load failures (kicked, missing game, etc.).
String _lobbyLoadErrorMessage(Object error) {
  if (error is LobbyViewDataException) return error.message;
  return "Can't find game";
}

/// Shell route body: loads [lobbyViewDataProvider] and wires lobby actions to
/// [commandRepositoryProvider] (Phase 2B.4).
class GameLobbyRouteScreen extends ConsumerStatefulWidget {
  const GameLobbyRouteScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<GameLobbyRouteScreen> createState() =>
      _GameLobbyRouteScreenState();
}

class _GameLobbyRouteScreenState extends ConsumerState<GameLobbyRouteScreen> {
  Future<void> _runCommand(Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmAndDiscardPreStart({
    required String adminPlayerId,
    required CommandRepository cmds,
  }) async {
    final ok = await ConfirmationDialog.show(
      context,
      title: 'Are you sure?',
      message: 'Are you sure you want to discard this game?',
      confirmLabel: 'Discard',
      cancelLabel: 'Back',
      destructive: true,
      uppercaseActionLabels: false,
    );
    if (ok != true || !mounted) return;
    await _runCommand(() async {
      await cmds.submitDiscardGame(
        gameId: widget.gameId,
        adminPlayerId: adminPlayerId,
      );
      await ref.read(homeViewDataProvider.notifier).silentRefresh();
      if (!mounted) return;
      context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currentGameProvider(widget.gameId));
    ref.listen<AsyncValue<GameSessionState>>(
      currentGameProvider(widget.gameId),
      (
        AsyncValue<GameSessionState>? previous,
        AsyncValue<GameSessionState> next,
      ) {
        final session = next.asData?.value;
        if (session == null) return;
        final gs = session.game.gameState;
        final prevGs = previous?.asData?.value?.game.gameState;

        // Pre-start discard: go home (not results / envelope flow).
        if (gs == GameState.discarded && prevGs == GameState.created) {
          if (!context.mounted) return;
          Future.microtask(() async {
            if (!context.mounted) return;
            await ref.read(homeViewDataProvider.notifier).silentRefresh();
            if (!context.mounted) return;
            context.go(AppRoutes.home);
          });
          return;
        }

        if (gs == GameState.tradingEnded || gs == GameState.gameFinalised) {
          if (!context.mounted) return;
          Future.microtask(() {
            if (!context.mounted) return;
            context.go(AppRoutes.gameResults(widget.gameId));
          });
        }
      },
    );

    final async = ref.watch(lobbyViewDataProvider(widget.gameId));
    final session = ref.watch(currentGameProvider(widget.gameId)).valueOrNull;
    final backNavigatesToHome = session != null &&
        gameStateShowsEnvelopeFlowOnly(session.game.gameState);

    return async.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(
        key: ValueKey('game-lobby-loading'),
        backgroundColor: AppColors.background,
        body: AsyncRouteLoadingBody(message: 'Loading lobby…'),
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
          message: _lobbyLoadErrorMessage(e),
          onRetry: () => ref.invalidate(lobbyViewDataProvider(widget.gameId)),
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
          backNavigatesToHome: backNavigatesToHome,
          onStartGame: () => _runCommand(() async {
            await cmds.submitStartGame(
              gameId: widget.gameId,
              adminPlayerId: playerId,
            );
          }),
          onEndGame: scenario.phase == GameLobbyPhase.preStart
              ? () => unawaited(
                    _confirmAndDiscardPreStart(
                      adminPlayerId: playerId,
                      cmds: cmds,
                    ),
                  )
              : () => _runCommand(() async {
                    await cmds.submitEndTrading(
                      gameId: widget.gameId,
                      adminPlayerId: playerId,
                    );
                  }),
          onEnterGame: () => context.go(AppRoutes.gameTrading(widget.gameId)),
          onJoinGame: () => _runCommand(() async {
            await cmds.submitJoinGame(gameId: widget.gameId, playerId: playerId);
          }),
          onLeaveGame: () => _runCommand(() async {
            await cmds.submitLeaveGame(gameId: widget.gameId, playerId: playerId);
            await ref.read(homeViewDataProvider.notifier).silentRefresh();
            if (!context.mounted) return;
            context.go(AppRoutes.home);
          }),
          onKickPlayer: (targetPlayerId) => _runCommand(() async {
            await cmds.submitKickPlayer(
              gameId: widget.gameId,
              adminPlayerId: playerId,
              targetPlayerId: targetPlayerId,
            );
            await ref.read(homeViewDataProvider.notifier).silentRefresh();
          }),
        );
      },
    );
  }
}
