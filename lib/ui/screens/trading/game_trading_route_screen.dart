import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/trading/personal_order.dart';
import '../../../data/enums/order_type.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/command_repository_provider.dart';
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

/// Shell route body: loads [tradingViewDataProvider] and wires trading actions
/// to [commandRepositoryProvider] (Phase 2B.5).
class GameTradingRouteScreen extends ConsumerWidget {
  const GameTradingRouteScreen({super.key, required this.gameId});

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tradingViewDataProvider(gameId));
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
          gameId: gameId,
          data: data,
          onEndGameFromMenu: () => _runCommand(context, ref, () async {
            await cmds.submitEndTrading(
              gameId: gameId,
              adminPlayerId: playerId,
            );
          }),
          onAddTime: (minutes) => _runCommand(context, ref, () async {
            await cmds.submitAddTime(
              gameId: gameId,
              adminPlayerId: playerId,
              additionalSeconds: minutes * 60,
            );
          }),
          submitCancelOrderCommand: (orderId) async {
            await cmds.submitCancelOrder(
              gameId: gameId,
              playerId: playerId,
              orderId: orderId,
            );
          },
          onSubmitNewOrder: (draft) async {
            final type = _orderTypeFromPersonalDraft(draft);
            await cmds.submitCreateOrder(
              gameId: gameId,
              playerId: playerId,
              type: type,
              quantityInitial: draft.quantityInitial,
              pricePerStock: draft.orderType == PersonalOrderType.limit
                  ? draft.limitPrice
                  : null,
            );
            await ref.read(ordersProvider(gameId).notifier).refresh();
          },
        );
      },
    );
  }
}
