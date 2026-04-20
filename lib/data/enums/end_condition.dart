/// How a game's trading period ends. `timed` auto-ends on a deadline; `endless`
/// only ends when the admin ends it manually. See PRD §games.end_condition.
enum EndCondition {
  timed('timed'),
  endless('endless');

  const EndCondition(this.wireValue);

  final String wireValue;

  static EndCondition fromWire(String value) {
    for (final e in EndCondition.values) {
      if (e.wireValue == value) return e;
    }
    throw ArgumentError.value(value, 'value', 'Unknown EndCondition');
  }

  static EndCondition? tryFromWire(String? value) {
    if (value == null) return null;
    for (final e in EndCondition.values) {
      if (e.wireValue == value) return e;
    }
    return null;
  }
}
