import '../../../core/results/game_results_pnl.dart';

/// One row in the final **Results** leaderboard (PnL driven by backend envelope snapshot).
class GameResultsPlayerRow {
  const GameResultsPlayerRow({
    required this.playerId,
    required this.displayName,
    required this.avatarInitials,
    required this.deltaCash,
    required this.deltaEnvelopes,
    required this.pnl,
  });

  final String playerId;
  final String displayName;
  final String avatarInitials;
  final double deltaCash;
  final double deltaEnvelopes;

  /// Final PnL after committed [`envelope_price`]. `null` when price not set yet.
  final double? pnl;
}

/// Final results screen (C7) — data comes from backend snapshots (`withEnvelopeUsd`).
class GameResultsViewData {
  const GameResultsViewData({
    required this.gameTitle,
    required this.isViewerAdmin,
    required this.players,
    required this.envelopePriceUsd,
    this.highlightPlayerId,
    this.gameEnded = false,
  });

  final String gameTitle;
  final bool isViewerAdmin;

  /// Committed envelope from server (mock stream-c). `null` ⇒ unset.
  final double? envelopePriceUsd;

  final List<GameResultsPlayerRow> players;

  /// Highlights that row with the green-tinted admin card border.
  final String? highlightPlayerId;

  /// When true, envelope updates and destructive end actions are frozen (game finished server-side).
  final bool gameEnded;

  /// Replace committed envelope and recompute rows as the backend would, sorted by PnL descending.
  GameResultsViewData withEnvelopeUsd(double? nextEnvelopeUsd) {
    final nextPlayers = players
        .map(
          (p) => GameResultsPlayerRow(
            playerId: p.playerId,
            displayName: p.displayName,
            avatarInitials: p.avatarInitials,
            deltaCash: p.deltaCash,
            deltaEnvelopes: p.deltaEnvelopes,
            pnl: computeFinalPnlFromEnvelope(
              deltaCash: p.deltaCash,
              deltaEnvelopes: p.deltaEnvelopes,
              envelopePriceUsd: nextEnvelopeUsd,
            ),
          ),
        )
        .toList(growable: false);

    nextPlayers.sort(
      (a, b) {
        final primary = comparePnlDescendingKnownLast(a.pnl, b.pnl);
        if (primary != 0) return primary;
        return a.playerId.compareTo(b.playerId);
      },
    );

    return GameResultsViewData(
      gameTitle: gameTitle,
      isViewerAdmin: isViewerAdmin,
      envelopePriceUsd: nextEnvelopeUsd,
      players: nextPlayers,
      highlightPlayerId: highlightPlayerId,
      gameEnded: gameEnded,
    );
  }

  GameResultsViewData withGameEnded(bool ended) {
    return GameResultsViewData(
      gameTitle: gameTitle,
      isViewerAdmin: isViewerAdmin,
      envelopePriceUsd: envelopePriceUsd,
      players: players,
      highlightPlayerId: highlightPlayerId,
      gameEnded: ended,
    );
  }
}
