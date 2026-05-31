import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/game_flow.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/trading/cancel_order_command.dart';
import '../../../core/trading/order_type_from_personal.dart';
import '../../../core/trading/personal_order.dart';
import '../../../data/enums/game_state.dart';
import '../../../data/models/game_session_state.dart';
import '../../../data/models/order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/game_repository_provider.dart';
import '../../../providers/trading_provider.dart';
import '../../../providers/best_effort_post_submit_refresh.dart';
import '../../../providers/view_data/pending_orders_view_data_provider.dart';
import '../../../providers/view_data/trading_view_data_provider.dart';
import '../../widgets/async_route_loading_body.dart';
import '../../widgets/fetched_error_panel.dart';
import 'game_trading_screen.dart';

export '../../../providers/best_effort_post_submit_refresh.dart'
    show bestEffortPostSubmitRefresh;

Future<void> _runTradingCommand(
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

/// Shell route body: loads [tradingViewDataProvider] and wires trading actions
/// to [commandRepositoryProvider] (Phase 2B.5).
///
/// Listens to [currentGameProvider] and **`go`**s to [AppRoutes.gameResults]
/// when [Game.gameState] is `trading_ended`, `game_finalised`, or `discarded`
/// while this trading route is still active.
class GameTradingRouteScreen extends ConsumerStatefulWidget {
  const GameTradingRouteScreen({super.key, required this.gameId});

  final String gameId;

  @override
  ConsumerState<GameTradingRouteScreen> createState() =>
      _GameTradingRouteScreenState();
}

class _GameTradingRouteScreenState
    extends ConsumerState<GameTradingRouteScreen> {
  var _scheduledNonLiveRedirect = false;
  Timer? _eligibleGamesPoll;

  @override
  void initState() {
    super.initState();
    // Keep switchable-game list live (same interval as Pending Orders tab).
    _eligibleGamesPoll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      unawaited(
        ref.read(pendingOrdersViewDataProvider.notifier).silentRefresh(),
      );
    });
  }

  @override
  void dispose() {
    _eligibleGamesPoll?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameTradingRouteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gameId != widget.gameId) {
      _scheduledNonLiveRedirect = false;
    }
  }

  void _redirectIfGameNotLiveForTrading(GameSessionState session) {
    if (isGameLiveForTrading(session.game)) return;
    if (!context.mounted) return;
    final gs = session.game.gameState;
    if (gameStateShowsEnvelopeFlowOnly(gs)) {
      context.go(AppRoutes.gameResults(widget.gameId));
    } else if (gs == GameState.created) {
      context.go(AppRoutes.gameLobby(widget.gameId));
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _scheduleRedirectIfGameNotLiveForTrading(GameSessionState session) {
    if (_scheduledNonLiveRedirect) return;
    if (isGameLiveForTrading(session.game)) return;
    _scheduledNonLiveRedirect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final latest = ref.read(currentGameProvider(widget.gameId)).valueOrNull;
      if (latest == null) return;
      _redirectIfGameNotLiveForTrading(latest);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(currentGameProvider(widget.gameId));
    // Must watch here (not only inside tradingViewData.when) so chevron
    // reappears when eligible games go 1 → 2+ without opening the menu.
    final switchableTradingGames = ref
            .watch(pendingOrdersViewDataProvider)
            .valueOrNull
            ?.tradingGamesForNewOrder ??
        const [];
    final session = sessionAsync.valueOrNull;
    if (session != null) {
      _scheduleRedirectIfGameNotLiveForTrading(session);
    }
    ref.listen<AsyncValue<GameSessionState>>(
      currentGameProvider(widget.gameId),
      (
        AsyncValue<GameSessionState>? previous,
        AsyncValue<GameSessionState> next,
      ) {
        final nextSession = next.asData?.value;
        if (nextSession == null) return;
        if (isGameLiveForTrading(nextSession.game)) return;
        if (!context.mounted) return;
        Future.microtask(() {
          if (!context.mounted) return;
          _redirectIfGameNotLiveForTrading(nextSession);
        });
      },
    );

    final async = ref.watch(tradingViewDataProvider(widget.gameId));
    // `skipLoadingOnReload: true` keeps the previous trading dashboard visible
    // while the provider refetches due to backend deltas (orders / executions /
    // session updates). Without this, every refresh briefly drops back to the
    // loading scaffold and the screen flickers.
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(
        key: ValueKey('game-trading-loading'),
        backgroundColor: AppColors.background,
        body: AsyncRouteLoadingBody(message: 'Loading trading dashboard…'),
      ),
      error: (e, _) => Scaffold(
        key: const ValueKey('game-trading-error'),
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
          onRetry: () => ref.invalidate(tradingViewDataProvider(widget.gameId)),
        ),
      ),
      data: (data) {
        final viewer = ref.read(authControllerProvider).valueOrNull;
        final playerId = viewer?.playerId ?? data.currentPlayerId;
        final cmds = ref.read(commandRepositoryProvider);
        final session = ref.watch(currentGameProvider(widget.gameId)).valueOrNull;
        final backNavigatesToHome = session != null &&
            gameStateShowsEnvelopeFlowOnly(session.game.gameState);
        return GameTradingScreen(
          gameId: widget.gameId,
          data: data,
          switchableTradingGames: switchableTradingGames,
          onRefreshSwitchableGames: () async {
            await ref
                .read(pendingOrdersViewDataProvider.notifier)
                .silentRefresh();
            return ref
                    .read(pendingOrdersViewDataProvider)
                    .valueOrNull
                    ?.tradingGamesForNewOrder ??
                const [];
          },
          onRequestSwitchGame: (targetGameId) async {
            await ref
                .read(pendingOrdersViewDataProvider.notifier)
                .silentRefresh();
            final gameRepo = ref.read(gameRepositoryProvider);
            final ok = await validateTradingGameSwitchTarget(
              gameRepo: gameRepo,
              targetGameId: targetGameId,
              currentGameId: widget.gameId,
            );
            if (!ok) return;
            if (!context.mounted) return;
            context.go(AppRoutes.gameTrading(targetGameId));
          },
          liveChartSessionElapsed:
              ref.watch(chartSessionElapsedProvider(widget.gameId)),
          backNavigatesToHome: backNavigatesToHome,
          onEndGameFromMenu: () => _runTradingCommand(context, ref, () async {
            await cmds.submitEndTrading(
              gameId: widget.gameId,
              adminPlayerId: playerId,
            );
          }),
          onAddTime: (minutes) => _runTradingCommand(context, ref, () async {
            await cmds.submitAddTime(
              gameId: widget.gameId,
              adminPlayerId: playerId,
              additionalSeconds: minutes * 60,
            );
          }),
          submitCancelOrderCommand:
              ({required String orderId, required int quantityToCancel}) async {
            final list =
                ref.read(ordersProvider(widget.gameId)).valueOrNull ??
                    const <Order>[];
            Order? backend;
            for (final o in list) {
              if (o.orderId == orderId) {
                backend = o;
                break;
              }
            }
            final pendingQty = backend?.quantityCurrent ?? quantityToCancel;
            if (quantityToCancel >= pendingQty) {
              await cmds.submitCancelOrder(
                gameId: widget.gameId,
                playerId: playerId,
                orderId: orderId,
              );
              return CancelOrderSubmitOutcome.fullCommandQueued;
            }
            await cmds.submitPartialCancelOrder(
              gameId: widget.gameId,
              playerId: playerId,
              orderId: orderId,
              quantityToCancel: quantityToCancel,
            );
            return CancelOrderSubmitOutcome.partialCommandQueued;
          },
          onSubmitNewOrder: (draft) async {
            final type = orderTypeFromPersonalDraft(draft);
            // Only `submitCreateOrder` throwing should trigger the screen's
            // "Could not submit order" snackbar. See
            // [bestEffortPostSubmitRefresh] for why refresh failures are
            // swallowed instead of propagated.
            await cmds.submitCreateOrder(
              gameId: widget.gameId,
              playerId: playerId,
              type: type,
              quantityInitial: draft.quantityInitial,
              pricePerStock: draft.orderType == PersonalOrderType.limit
                  ? draft.limitPrice
                  : null,
            );
            await bestEffortPostSubmitRefresh([
              () => ref.read(ordersProvider(widget.gameId).notifier).refresh(),
              () => ref
                  .read(
                    pendingCreateOrderCommandsProvider(widget.gameId).notifier,
                  )
                  .refresh(),
            ]);
          },
        );
      },
    );
  }
}
