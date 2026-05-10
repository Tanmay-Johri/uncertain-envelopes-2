import '../../data/enums/game_state.dart';

/// States where only the results / envelope flow is valid — lobby and trading
/// routes must redirect here and must not offer trading or pre-game actions.
bool gameStateShowsEnvelopeFlowOnly(GameState state) {
  return state == GameState.tradingEnded ||
      state == GameState.gameFinalised ||
      state == GameState.discarded;
}
