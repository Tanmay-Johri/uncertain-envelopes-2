import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/game_flow.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/trading/order_type_from_personal.dart';
import '../../../core/trading/personal_order.dart';
import '../../../data/models/game_session_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/trading_provider.dart';
import '../../../providers/best_effort_post_submit_refresh.dart';
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
        if (!gameStateShowsEnvelopeFlowOnly(session.game.gameState)) return;
        if (!context.mounted) return;
        Future.microtask(() {
          if (!context.mounted) return;
          context.go(AppRoutes.gameResults(widget.gameId));
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
          submitCancelOrderCommand: (orderId) async {
            await cmds.submitCancelOrder(
              gameId: widget.gameId,
              playerId: playerId,
              orderId: orderId,
            );
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
