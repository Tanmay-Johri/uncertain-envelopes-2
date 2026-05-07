/// Visibility of a game. `public` shows in the public games list, `private`
/// is only reachable via joining code. See PRD §games.game_security.
enum GameSecurity {
  public('public'),
  private('private');

  const GameSecurity(this.wireValue);

  final String wireValue;

  static String toWire(GameSecurity value) => value.wireValue;

  static GameSecurity fromWire(String value) {
    for (final s in GameSecurity.values) {
      if (s.wireValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'Unknown GameSecurity');
  }

  static GameSecurity? tryFromWire(String? value) {
    if (value == null) return null;
    for (final s in GameSecurity.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}
