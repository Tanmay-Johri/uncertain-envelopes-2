import '../../data/enums/game_state.dart';
import '../../data/models/game.dart';
import '../../data/repositories/game_repository.dart';

/// States where only the results / envelope flow is valid — lobby and trading
/// routes must redirect here and must not offer trading or pre-game actions.
bool gameStateShowsEnvelopeFlowOnly(GameState state) {
  return state == GameState.tradingEnded ||
      state == GameState.gameFinalised ||
      state == GameState.discarded;
}

/// True when the live trading dashboard is valid for [game].
bool isGameLiveForTrading(Game game) {
  return game.gameState == GameState.tradingStarted;
}

/// Validates a game-switcher target using a fresh [GameRepository.fetchGame]
/// read (not the cached switcher list). Returns false for stale / ended games.
Future<bool> validateTradingGameSwitchTarget({
  required GameRepository gameRepo,
  required String targetGameId,
  required String currentGameId,
}) async {
  if (targetGameId == currentGameId) return false;
  final game = await gameRepo.fetchGame(targetGameId);
  return game != null && isGameLiveForTrading(game);
}
