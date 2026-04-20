/// Every user (and system) action against a game is modelled as a command row.
/// The server processes commands sequentially per game. See PRD §commands.
enum CommandType {
  createGame('create_game'),
  joinGame('join_game'),
  leaveGame('leave_game'),
  kickPlayer('kick_player'),
  startGame('start_game'),
  createOrder('create_order'),
  cancelOrder('cancel_order'),
  endTrading('end_trading'),
  setEnvelopePrice('set_envelope_price'),
  finaliseGame('finalise_game'),
  discardGame('discard_game'),
  addTime('add_time');

  const CommandType(this.wireValue);

  final String wireValue;

  /// `create_game` is the only command where `command_game_id` is null,
  /// because the game does not exist when the command is submitted.
  bool get requiresGameId => this != CommandType.createGame;

  static CommandType fromWire(String value) {
    for (final c in CommandType.values) {
      if (c.wireValue == value) return c;
    }
    throw ArgumentError.value(value, 'value', 'Unknown CommandType');
  }

  static CommandType? tryFromWire(String? value) {
    if (value == null) return null;
    for (final c in CommandType.values) {
      if (c.wireValue == value) return c;
    }
    return null;
  }
}
