import 'dart:math' as math;

/// Step for ± controls on limit price (currency units).
const kLimitPriceStep = 1.0;

/// Smallest number of fraction digits shown in the limit field / stance line.
const int kLimitPriceMinFractionDigits = 2;

/// Fraction digits to use when formatting [d], based on how many digits the
/// user typed after `.` in [rawTrimmed] (minimum [kLimitPriceMinFractionDigits]).
int limitPriceFractionDigitsFromRaw(String rawTrimmed) {
  final dot = rawTrimmed.indexOf('.');
  if (dot < 0) return kLimitPriceMinFractionDigits;
  var count = 0;
  for (var i = dot + 1; i < rawTrimmed.length; i++) {
    final c = rawTrimmed.codeUnitAt(i);
    if (c >= 48 && c <= 57) {
      count++;
    } else {
      break;
    }
  }
  return math.max(kLimitPriceMinFractionDigits, count);
}

/// Display string for a limit [double]: at least two fraction digits; more if
/// [rawHint] (the field text) includes additional decimal places.
String formatLimitPriceForField(double d, {String? rawHint}) {
  final t = rawHint?.trim() ?? '';
  final n = t.isEmpty
      ? kLimitPriceMinFractionDigits
      : limitPriceFractionDigitsFromRaw(t);
  return d.toStringAsFixed(n);
}

/// After edit: if empty or not a positive finite number, reset to [fallbackMarket]
/// (or clear the field when [fallbackMarket] is `null`).
/// Otherwise format [d] with [formatLimitPriceForField].
String normalizeLimitPriceFieldText(String raw, double? fallbackMarket) {
  final t = raw.trim();
  if (t.isEmpty) {
    if (fallbackMarket == null) return '';
    return formatLimitPriceForField(fallbackMarket);
  }
  final d = double.tryParse(t);
  if (d == null || d.isNaN || d.isInfinite || d <= 0) {
    if (fallbackMarket == null) return '';
    return formatLimitPriceForField(fallbackMarket);
  }
  return formatLimitPriceForField(d, rawHint: t);
}

/// Limit price for submit: **exact** parsed double; must be **> 0**.
double? parseLimitPriceForSubmit(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final d = double.tryParse(t);
  if (d == null || d.isNaN || d.isInfinite || d <= 0) return null;
  return d;
}

/// Minimum limit after decrement (avoid non-positive).
const kLimitPriceMinPositive = 0.01;
