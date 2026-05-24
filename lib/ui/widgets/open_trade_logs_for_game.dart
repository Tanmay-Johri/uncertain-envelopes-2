import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/view_data/trade_logs_for_game_provider.dart';
import '../screens/trading/trading_view_data.dart';
import 'trade_logs_sheet.dart';

/// Loads trade logs for [gameId] then opens [TradeLogsSheet].
Future<void> openTradeLogsForGame(
  BuildContext context,
  WidgetRef ref,
  String gameId,
) async {
  final viewer = ref.read(authControllerProvider).valueOrNull;
  if (viewer == null || !context.mounted) return;

  try {
    final logs = await ref.read(tradeLogsForGameProvider(gameId).future);
    if (!context.mounted) return;
    await TradeLogsSheet.show(
      context,
      logs: logs,
      viewerPlayerId: viewer.playerId,
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
  }
}

/// Opens [TradeLogsSheet] with a pre-built list (mocks / tests).
Future<void> openTradeLogsWithEntries(
  BuildContext context, {
  required List<TradeLogEntry> logs,
  required String viewerPlayerId,
}) {
  return TradeLogsSheet.show(
    context,
    logs: logs,
    viewerPlayerId: viewerPlayerId,
  );
}
