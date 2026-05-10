import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/game_state.dart';
import '../../core/trading/personal_order_from_order.dart';
import '../../ui/screens/orders/pending_orders_view_data.dart';
import '../auth_provider.dart';
import '../game_repository_provider.dart';
import '../trading_repository_providers.dart';

part 'pending_orders_view_data_provider.g.dart';

/// Thrown when [pendingOrdersViewDataProvider] cannot build.
class PendingOrdersViewDataException implements Exception {
  const PendingOrdersViewDataException(this.message);
  final String message;

  @override
  String toString() => 'PendingOrdersViewDataException($message)';
}

/// Cross-game pending resting / in-flight orders plus games where the player
/// may create orders (`trading_started`).
@riverpod
Future<PendingOrdersScreenData> pendingOrdersViewData(Ref ref) async {
  final player = ref.watch(authControllerProvider).valueOrNull;
  if (player == null) {
    throw const PendingOrdersViewDataException(
      'Sign in to view pending orders.',
    );
  }

  final ordersRepo = ref.watch(orderRepositoryProvider);
  final gamesRepo = ref.watch(gameRepositoryProvider);

  final ordersFuture =
      ordersRepo.fetchPendingOrdersAcrossGames(player.playerId);
  final joinedFuture = gamesRepo.fetchJoinedGames(player.playerId);
  final orders = await ordersFuture;
  final joinedGames = await joinedFuture;

  final tradingGamesForNewOrder = <TradingOrderTargetGame>[
    for (final g in joinedGames)
      if (g.gameState == GameState.tradingStarted)
        TradingOrderTargetGame(
          gameId: g.gameId,
          gameTitle: g.gameName,
          gameDescription: g.gameDescription ?? '',
        ),
  ];

  final out = <PendingOrderListItem>[];
  for (final o in orders) {
    final g = await gamesRepo.fetchGame(o.gameId);
    if (g == null) continue;
    out.add(
      PendingOrderListItem(
        gameId: o.gameId,
        gameTitle: g.gameName,
        gameDescription: g.gameDescription ?? '',
        order: personalOrderFromOrder(o),
      ),
    );
  }

  return PendingOrdersScreenData(
    items: out,
    tradingGamesForNewOrder: tradingGamesForNewOrder,
  );
}
