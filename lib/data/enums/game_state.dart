/// Lifecycle state of a game row.
///
/// Wire values come directly from Postgres and must match the schema enum
/// exactly. Case sensitive. See PRD §games.game_state.
enum GameState {
  created('created'),
  tradingStarted('trading_started'),
  tradingEnded('trading_ended'),
  gameFinalised('game_finalised'),
  discarded('discarded');

  const GameState(this.wireValue);

  final String wireValue;

  static String toWire(GameState value) => value.wireValue;

  static GameState fromWire(String value) {
    for (final state in GameState.values) {
      if (state.wireValue == value) return state;
    }
    throw ArgumentError.value(value, 'value', 'Unknown GameState');
  }

  static GameState? tryFromWire(String? value) {
    if (value == null) return null;
    for (final state in GameState.values) {
      if (state.wireValue == value) return state;
    }
    return null;
  }
}
