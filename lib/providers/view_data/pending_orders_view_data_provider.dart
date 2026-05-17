import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/game_state.dart';
import '../../data/models/order.dart';
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
///
/// [silentRefresh] updates rows **without** going through [AsyncLoading], so
/// periodic refreshes do not flash the loading skeleton.
@Riverpod(keepAlive: true)
class PendingOrdersViewData extends _$PendingOrdersViewData {
  static const _recentClosedWindow = Duration(minutes: 1);

  @override
  Future<PendingOrdersScreenData> build() async => _load();

  /// Background refresh (timer / post-command). Keeps prior data visible
  /// while fetching — no loading flicker on success.
  Future<void> silentRefresh() async {
    try {
      final next = await _load();
      state = AsyncValue.data(next);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<PendingOrdersScreenData> _load() async {
    final player = ref.watch(authControllerProvider).valueOrNull;
    if (player == null) {
      throw const PendingOrdersViewDataException(
        'Sign in to view pending orders.',
      );
    }

    final ordersRepo = ref.watch(orderRepositoryProvider);
    final gamesRepo = ref.watch(gameRepositoryProvider);

    final sinceUtc = DateTime.now().toUtc().subtract(_recentClosedWindow);
    final pendingFuture =
        ordersRepo.fetchPendingOrdersAcrossGames(player.playerId);
    final closedFuture =
        ordersRepo.fetchTerminalOrdersUpdatedSinceAcrossGames(
      player.playerId,
      sinceUtc,
    );
    final joinedFuture = gamesRepo.fetchJoinedGames(player.playerId);

    final pending = await pendingFuture;
    final closed = await closedFuture;
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

    final pendingIds = pending.map((o) => o.orderId).toSet();
    final closedOnly =
        closed.where((o) => !pendingIds.contains(o.orderId)).toList();

    Future<PendingOrderListItem?> rowFor(Order o) async {
      final g = await gamesRepo.fetchGame(o.gameId);
      if (g == null) return null;
      return PendingOrderListItem(
        gameId: o.gameId,
        gameTitle: g.gameName,
        gameDescription: g.gameDescription ?? '',
        order: personalOrderFromOrder(o),
        isRecentlyClosed: false,
      );
    }

    Future<PendingOrderListItem?> closedRowFor(Order o) async {
      final g = await gamesRepo.fetchGame(o.gameId);
      if (g == null) return null;
      return PendingOrderListItem(
        gameId: o.gameId,
        gameTitle: g.gameName,
        gameDescription: g.gameDescription ?? '',
        order: personalOrderFromOrder(o),
        isRecentlyClosed: true,
      );
    }

    final out = <PendingOrderListItem>[];
    for (final o in pending) {
      final row = await rowFor(o);
      if (row != null) out.add(row);
    }
    for (final o in closedOnly) {
      final row = await closedRowFor(o);
      if (row != null) out.add(row);
    }

    return PendingOrdersScreenData(
      items: pendingOrderListItemsSortedNewestFirst(out),
      tradingGamesForNewOrder: tradingGamesForNewOrder,
    );
  }
}
