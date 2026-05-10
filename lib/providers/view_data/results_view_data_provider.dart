import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/enums/game_state.dart';
import '../../data/models/game_session_state.dart';
import '../../ui/screens/results/results_view_data.dart';
import '../auth_provider.dart';
import '../game_provider.dart';
import 'lobby_view_data_provider.dart';

part 'results_view_data_provider.g.dart';

/// Thrown when [resultsViewDataProvider] cannot build (e.g. not signed in).
class ResultsViewDataException implements Exception {
  const ResultsViewDataException(this.message);
  final String message;

  @override
  String toString() => 'ResultsViewDataException($message)';
}

/// Maps a loaded session + viewer into [GameResultsViewData] (Phase 2B.6).
GameResultsViewData buildGameResultsViewDataFromSession({
  required GameSessionState session,
  required String viewerPlayerId,
}) {
  final game = session.game;
  final sorted = [...session.players]
    ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));
  final rows = <GameResultsPlayerRow>[
    for (final p in sorted)
      GameResultsPlayerRow(
        playerId: p.mapPlayerId,
        displayName: lobbyDisplayUsername(p.mapPlayerId),
        avatarInitials: lobbyInitials(p.mapPlayerId),
        deltaCash: p.deltaCash,
        deltaEnvelopes: p.deltaEnvelopes.toDouble(),
        pnl: null,
      ),
  ];

  final gameEnded = game.gameState == GameState.gameFinalised ||
      game.gameState == GameState.discarded;

  final base = GameResultsViewData(
    gameTitle: game.gameName,
    isViewerAdmin: game.adminPlayerId == viewerPlayerId,
    envelopePriceUsd: game.envelopePrice,
    players: rows,
    highlightPlayerId: viewerPlayerId,
    gameEnded: gameEnded,
  );
  return base.withEnvelopeUsd(game.envelopePrice);
}

/// Final results leaderboard + envelope state for [gameId].
@riverpod
Future<GameResultsViewData> resultsViewData(Ref ref, String gameId) async {
  final viewer = await ref.watch(authControllerProvider.future);
  if (viewer == null) {
    throw const ResultsViewDataException('Sign in to view results.');
  }
  final session = await ref.watch(currentGameProvider(gameId).future);
  return buildGameResultsViewDataFromSession(
    session: session,
    viewerPlayerId: viewer.playerId,
  );
}
