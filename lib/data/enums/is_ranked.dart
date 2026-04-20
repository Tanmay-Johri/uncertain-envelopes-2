/// Whether a game is ranked (affects player stats) or casual. The PRD models
/// this explicitly as an enum rather than a boolean so other variants can be
/// added later without a migration.
enum IsRanked {
  ranked('ranked'),
  casual('casual');

  const IsRanked(this.wireValue);

  final String wireValue;

  static IsRanked fromWire(String value) {
    for (final r in IsRanked.values) {
      if (r.wireValue == value) return r;
    }
    throw ArgumentError.value(value, 'value', 'Unknown IsRanked');
  }

  static IsRanked? tryFromWire(String? value) {
    if (value == null) return null;
    for (final r in IsRanked.values) {
      if (r.wireValue == value) return r;
    }
    return null;
  }
}
