/// Per-player lobby status inside a single game. See PRD §games_players.lobby_status.
enum LobbyStatus {
  playing('playing'),
  finished('finished');

  const LobbyStatus(this.wireValue);

  final String wireValue;

  static String toWire(LobbyStatus value) => value.wireValue;

  static LobbyStatus fromWire(String value) {
    for (final s in LobbyStatus.values) {
      if (s.wireValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'Unknown LobbyStatus');
  }

  static LobbyStatus? tryFromWire(String? value) {
    if (value == null) return null;
    for (final s in LobbyStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}
