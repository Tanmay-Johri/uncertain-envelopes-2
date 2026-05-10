import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/trading/personal_order.dart';
import '../../../data/enums/game_state.dart';
import '../../../data/enums/order_type.dart';
import '../../../data/models/game_session_state.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/trading_provider.dart';
import '../../../providers/view_data/trading_view_data_provider.dart';
import 'game_trading_screen.dart';

OrderType _orderTypeFromPersonalDraft(PersonalOrder o) {
  return switch ((o.side, o.orderType)) {
    (PersonalOrderSide.buy, PersonalOrderType.limit) => OrderType.limitBuy,
    (PersonalOrderSide.buy, PersonalOrderType.market) => OrderType.marketBuy,
    (PersonalOrderSide.sell, PersonalOrderType.limit) => OrderType.limitSell,
    (PersonalOrderSide.sell, PersonalOrderType.market) => OrderType.marketSell,
  };
}

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

/// When the server moves the game out of active trading, the results flow
/// should open without requiring a manual deep link (gaps-stream-c).
bool _gameStateOpensResults(GameState s) {
  return s == GameState.tradingEnded ||
      s == GameState.gameFinalised ||
      s == GameState.discarded;
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
        if (!_gameStateOpensResults(session.game.gameState)) return;
        if (!context.mounted) return;
        Future.microtask(() {
          if (!context.mounted) return;
          context.go(AppRoutes.gameResults(widget.gameId));
        });
      },
    );

    final async = ref.watch(tradingViewDataProvider(widget.gameId));
    return async.when(
      loading: () => const Scaffold(
        key: ValueKey('game-trading-loading'),
        body: Center(child: CircularProgressIndicator()),
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
        final playerId = viewer?.playerId ?? data.currentPlayerId;
        final cmds = ref.read(commandRepositoryProvider);
        return GameTradingScreen(
          gameId: widget.gameId,
          data: data,
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
            final type = _orderTypeFromPersonalDraft(draft);
            await cmds.submitCreateOrder(
              gameId: widget.gameId,
              playerId: playerId,
              type: type,
              quantityInitial: draft.quantityInitial,
              pricePerStock: draft.orderType == PersonalOrderType.limit
                  ? draft.limitPrice
                  : null,
            );
            await Future.wait([
              ref.read(ordersProvider(widget.gameId).notifier).refresh(),
              ref
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
