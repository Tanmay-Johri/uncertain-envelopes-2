import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/command.dart';
import '../data/models/execution.dart';
import '../data/models/game.dart';
import '../data/models/game_player.dart';
import '../data/models/order.dart';
import '../providers/game_provider.dart';
import '../providers/trading_provider.dart';
import 'game_realtime_service.dart';

/// Concrete [GameRealtimeTarget] that drives the B8 + B9 notifiers
/// through a [ProviderContainer] (or any Ref). Used in production;
/// tests use a plain fake implementation instead of going through
/// Riverpod.
class RiverpodRealtimeTarget implements GameRealtimeTarget {
  RiverpodRealtimeTarget({required this.ref, required this.gameId});

  final Ref ref;
  final String gameId;

  @override
  int? get currentVersion =>
      ref.read(currentGameProvider(gameId)).valueOrNull?.game.stateVersion;

  @override
  void applyGameUpdate(Game game) {
    ref.read(currentGameProvider(gameId).notifier).applyGameUpdate(game);
  }

  @override
  void applyPlayerUpsert(GamePlayer player) {
    ref.read(currentGameProvider(gameId).notifier).applyPlayerUpsert(player);
  }

  @override
  void applyPlayerRemoval(String playerId) {
    ref
        .read(currentGameProvider(gameId).notifier)
        .applyPlayerRemoval(playerId);
  }

  @override
  void applyOrderUpsert(Order order) {
    ref.read(ordersProvider(gameId).notifier).upsert(order);
  }

  @override
  void applyOrderRemoval(String orderId) {
    ref.read(ordersProvider(gameId).notifier).remove(orderId);
  }

  @override
  void applyExecutionInsert(Execution execution) {
    ref.read(executionsProvider(gameId).notifier).add(execution);
  }

  @override
  void applyPendingCreateOrderCommandUpsert(Command command) {
    ref
        .read(pendingCreateOrderCommandsProvider(gameId).notifier)
        .mergeRealtime(command);
  }

  @override
  void applyPendingCreateOrderCommandRemoval(String commandId) {
    ref
        .read(pendingCreateOrderCommandsProvider(gameId).notifier)
        .removeByCommandId(commandId);
  }

  @override
  Future<void> refreshAll() async {
    await Future.wait([
      ref.read(currentGameProvider(gameId).notifier).refresh(),
      ref.read(ordersProvider(gameId).notifier).refresh(),
      ref.read(executionsProvider(gameId).notifier).refresh(),
      ref.read(pendingCreateOrderCommandsProvider(gameId).notifier).refresh(),
    ]);
  }
}
