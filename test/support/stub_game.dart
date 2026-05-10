import 'package:uncertain_envelopes_2/data/enums/end_condition.dart';
import 'package:uncertain_envelopes_2/data/enums/game_security.dart';
import 'package:uncertain_envelopes_2/data/enums/game_state.dart';
import 'package:uncertain_envelopes_2/data/enums/is_ranked.dart';
import 'package:uncertain_envelopes_2/data/models/game.dart';

/// Minimal [Game] row for router / provider tests (Phase 2 integration).
Game stubGameForRouterTests({
  required String gameId,
  GameState gameState = GameState.tradingStarted,
  String gameName = 'Forex Masters',
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Game(
    gameId: gameId,
    gameName: gameName,
    gameDescription: null,
    gameCreatedAt: now,
    gameSecurity: GameSecurity.public,
    isRanked: IsRanked.casual,
    gameMaxPlayers: 16,
    joiningCode: 'ABCDE',
    endCondition: EndCondition.timed,
    totalDecidedDurationSeconds: 3600,
    endTimeDecided: now.add(const Duration(hours: 1)),
    startTime: now,
    endTimeActual: null,
    gameState: gameState,
    adminPlayerId: 'admin-1',
    lastTradedPrice: 150,
    envelopePrice: null,
    stateVersion: 0,
    updatedAt: now,
  );
}
