import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/trading/trade_logs_from_executions.dart';
import '../../data/models/player.dart';
import '../../ui/screens/trading/trading_view_data.dart';
import '../auth_provider.dart';
import '../player_repository_provider.dart';
import '../trading_provider.dart';
import 'lobby_view_data_provider.dart';

part 'trade_logs_for_game_provider.g.dart';

/// Executed trades for [gameId], for the transaction log sheet on any screen.
@riverpod
Future<List<TradeLogEntry>> tradeLogsForGame(Ref ref, String gameId) async {
  final viewer = await ref.watch(authControllerProvider.future);
  if (viewer == null) {
    return const [];
  }

  final orders = await ref.watch(ordersProvider(gameId).future);
  final executions = await ref.watch(executionsProvider(gameId).future);
  final ordersById = {for (final o in orders) o.orderId: o};

  final participantIds = <String>{
    for (final e in executions) ...[
      if (ordersById[e.sellOrderId] != null)
        ordersById[e.sellOrderId]!.createdByPlayerId,
      if (ordersById[e.buyOrderId] != null)
        ordersById[e.buyOrderId]!.createdByPlayerId,
    ],
  };

  final profilesById = participantIds.isEmpty
      ? <String, Player>{}
      : await ref.read(playerRepositoryProvider).fetchProfilesByIds(
            participantIds.toList(),
          );

  return tradeLogsFromExecutions(
    executions: executions,
    ordersById: ordersById,
    nameForPlayer: (id) => displayUsernameForPlayer(id, profilesById),
  );
}
