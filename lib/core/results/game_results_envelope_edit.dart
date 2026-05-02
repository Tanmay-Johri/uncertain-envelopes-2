/// Parse envelope price from admin text field: optional leading `-`, digits,
/// at most one `.`, max **five** fractional digits. Empty → null.
///
/// Incomplete decimals like `"10."` parse as **10.0** so UPDATE can enable once
/// the numeric value is determined.
double? parseEnvelopePriceUsd(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;

  final neg = t.startsWith('-');
  var s = neg ? t.substring(1).trimLeft() : t;
  if (s.isEmpty) return null;

  final dot = s.indexOf('.');
  if (dot >= 0) {
    final frac = s.substring(dot + 1);
    if (frac.length > 5) return null;
    if (!RegExp(r'^\d*$').hasMatch(frac)) return null;
  }

  if (!RegExp(r'^\d+\.?\d*$').hasMatch(s)) return null;
  if (s == '.') return null;

  final v = double.tryParse(s.endsWith('.') ? '${s}0' : s);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return neg ? -v : v;
}

/// Initial text for editing from a committed USD value (no `$`).
String envelopePriceSeedForEditing(double? committedUsd) {
  if (committedUsd == null) return '';
  if (committedUsd.isNaN || committedUsd.isInfinite) return '';
  final neg = committedUsd < 0;
  final x = committedUsd.abs();
  var s = x.toStringAsFixed(5);
  final dot = s.indexOf('.');
  if (dot < 0) return neg ? '-$s' : s;
  var frac = s.substring(dot + 1);
  while (frac.length > 2 && frac.endsWith('0')) {
    frac = frac.substring(0, frac.length - 1);
  }
  final body = '${s.substring(0, dot)}.$frac';
  return neg ? '-$body' : body;
}
