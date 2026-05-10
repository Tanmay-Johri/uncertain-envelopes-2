import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/game_security.dart';
import '../../data/enums/game_state.dart';
import '../../data/enums/is_ranked.dart';
import '../../data/models/game_player.dart';
import '../../ui/screens/history/game_history_view_data.dart';
import '../auth_provider.dart';
import '../game_repository_provider.dart';
import 'lobby_view_data_provider.dart';

part 'game_history_view_data_provider.g.dart';

/// Thrown when [gameHistoryViewDataProvider] cannot build.
class GameHistoryViewDataException implements Exception {
  const GameHistoryViewDataException(this.message);
  final String message;

  @override
  String toString() => 'GameHistoryViewDataException($message)';
}

/// Completed games for [GameHistoryScreen], derived from joined games in
/// terminal states (Phase 2B.9 — no dedicated SQL yet).
@riverpod
Future<List<GameHistoryEntry>> gameHistoryViewData(Ref ref) async {
  final viewer = ref.watch(authControllerProvider).valueOrNull;
  if (viewer == null) {
    throw const GameHistoryViewDataException(
      'Sign in to view game history.',
    );
  }

  final repo = ref.watch(gameRepositoryProvider);
  final joined = await repo.fetchJoinedGames(viewer.playerId);
  final terminal = joined
      .where(
        (g) =>
            g.gameState == GameState.gameFinalised ||
            g.gameState == GameState.discarded,
      )
      .toList()
    ..sort((a, b) {
      final ea = a.endTimeActual ?? a.updatedAt;
      final eb = b.endTimeActual ?? b.updatedAt;
      return eb.compareTo(ea);
    });

  final out = <GameHistoryEntry>[];
  for (final g in terminal) {
    final players = await repo.fetchGamePlayers(g.gameId);
    final sorted = [...players]..sort((a, b) => b.pnl.compareTo(a.pnl));
    GamePlayer? viewerRow;
    for (final p in players) {
      if (p.mapPlayerId == viewer.playerId) {
        viewerRow = p;
        break;
      }
    }
    out.add(
      GameHistoryEntry(
        id: g.gameId,
        title: g.gameName,
        description: g.gameDescription ?? '',
        viewerPnl: viewerRow?.pnl ?? 0,
        securityType:
            g.gameSecurity == GameSecurity.public ? 'Public' : 'Private',
        isRanked: g.isRanked == IsRanked.ranked,
        adminName: lobbyDisplayUsername(g.adminPlayerId),
        envelopePriceUsd: g.envelopePrice,
        startedAt: g.startTime,
        endedAt: g.endTimeActual,
        playerResults: [
          for (final p in sorted)
            GameHistoryPlayerResult(
              playerId: p.mapPlayerId,
              displayName: lobbyDisplayUsername(p.mapPlayerId),
              pnl: p.pnl,
            ),
        ],
      ),
    );
  }
  return out;
}
