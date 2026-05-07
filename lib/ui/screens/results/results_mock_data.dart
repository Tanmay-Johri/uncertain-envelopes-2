import 'results_view_data.dart';

/// Mock id for **admin** viewer (envelope starts unset until **UPDATE FOR EVERYONE**).
const kMockGameResultsAdminId = 'gResults';

/// Mock id for **non-admin** viewer.
const kMockGameResultsPlayerId = 'gResultsPlayer';

/// Admin-focused scenario alias (historical); same as **admin** preset with no committed price yet.
const kMockGameResultsAdminNoPriceId = 'gResultsNoPrice';

GameResultsViewData mockGameResultsViewDataForAdmin() {
  return _baseline(isViewerAdmin: true).withEnvelopeUsd(null);
}

GameResultsViewData mockGameResultsViewDataForPlayer() {
  return _baseline(isViewerAdmin: false).withEnvelopeUsd(null);
}

GameResultsViewData mockGameResultsViewDataAdminNoEnvelope() {
  return mockGameResultsViewDataForAdmin();
}

/// Raw template: deltas only; caller applies [.withEnvelopeUsd] for the backend snapshot.
GameResultsViewData _baseline({required bool isViewerAdmin}) {
  return GameResultsViewData(
    gameTitle: 'Forex Masters',
    isViewerAdmin: isViewerAdmin,
    envelopePriceUsd: null,
    highlightPlayerId: 'p_admin',
    players: const [
      GameResultsPlayerRow(
        playerId: 'p_admin',
        displayName: 'AdminUser',
        avatarInitials: 'AD',
        deltaCash: 500,
        deltaEnvelopes: -2,
        pnl: null,
      ),
      GameResultsPlayerRow(
        playerId: 'p_js',
        displayName: 'JohnSmith',
        avatarInitials: 'JS',
        deltaCash: 120,
        deltaEnvelopes: 0,
        pnl: null,
      ),
      GameResultsPlayerRow(
        playerId: 'p_tk',
        displayName: 'TraderKing',
        avatarInitials: 'TK',
        deltaCash: -400,
        deltaEnvelopes: 4,
        pnl: null,
      ),
      GameResultsPlayerRow(
        playerId: 'p_cw',
        displayName: 'CryptoWhale',
        avatarInitials: 'ME',
        deltaCash: -800,
        deltaEnvelopes: 10,
        pnl: null,
      ),
    ],
  );
}

GameResultsViewData mockGameResultsViewDataForGameId(String gameId) {
  switch (gameId) {
    case kMockGameResultsAdminId:
      return mockGameResultsViewDataForAdmin();
    case kMockGameResultsAdminNoPriceId:
      return mockGameResultsViewDataAdminNoEnvelope();
    case kMockGameResultsPlayerId:
      return mockGameResultsViewDataForPlayer();
    default:
      return mockGameResultsViewDataForPlayer();
  }
}
