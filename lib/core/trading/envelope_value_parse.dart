const double _kNearOne = 1e-6;

/// Treats [s] with trailing `.` (e.g. `1.`) as **1.0**; strips whitespace;
/// returns `null` if not parseable.
double? tryParseAssumptionValue(String s) {
  var t = s.trim();
  if (t.isEmpty) return null;
  if (t.endsWith('.')) t = t.substring(0, t.length - 1);
  t = t.trim();
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

bool isCloseTo(double a, double b) {
  if (a.isNaN && b.isNaN) return true;
  if (a.isNaN || b.isNaN) return false;
  return (a - b).abs() < _kNearOne;
}

/// Digits for the envelope text field (no leading `$` — add via [TextField] prefix).
String formatAssumptionInputNumber(double v) {
  if (v.isNaN) return '0';
  if (v == v.roundToDouble() && v.abs() < 1e12) {
    return v.round().toString();
  }
  if ((v * 100).round() / 100 == v) {
    return v.toStringAsFixed(2);
  }
  return ((v * 100).round() / 100).toStringAsFixed(2);
}

String formatAssumptionText(double v) {
  if (v.isNaN) return r'$0';
  if (v == v.roundToDouble() && v.abs() < 1e12) {
    return r'$' + v.round().toString();
  }
  // Two-decimal for fractional display (mock shows $125.00).
  if ((v * 100).round() / 100 == v) {
    return r'$' + v.toStringAsFixed(2);
  }
  // Avoid ugly strings for irrationals; keep 2 dp.
  return r'$' + ((v * 100).round() / 100).toStringAsFixed(2);
}
