import 'dart:math' as math;

import 'envelope_value_parse.dart' show isCloseTo;

/// “Nice” slider bounds for a **(raw lower, raw upper)** pair from the ±50% half
/// range — no implied center. Use the **log-decade** map when *both* raws are
/// `< 10` (typical for small-envelope raws, e.g. 0.325 / 0.975):
/// - **Lower:** `10^floor(log10 L)` for `L > 0` (0 → 0)
/// - **Upper:** `10^ceil(log10 U)` for `U > 0` (0 → 0)
/// So 0.975 → **1**, 1.25 → **10**; 0.325 → **0.1** as the decade tick below.
/// When **either** raw is `≥ 10`, use the **integer** half-range: truncate to
/// int, `d = min(digits)`, `step = 10^(d-1)`, floor/ceil (same as large `v` case).
/// Optional clamp: e.g. `[0,1]` or `[0,10]` for UI tiers, then the ≈1 display rules.
({double min, double max}) envelopeSliderBoundsFromRaws(
  double rawL,
  double rawU, {
  double? minCap,
  double? maxCap,
  bool useIntegerPath = false,
}) {
  if (rawL.isNaN || rawU.isNaN) return (min: 0, max: 0);
  if (rawL < 0) rawL = 0;
  if (rawU < 0) rawU = 0;
  if (rawU < rawL) {
    final t = rawL;
    rawL = rawU;
    rawU = t;
  }

  late ({double min, double max}) pair;
  if (useIntegerPath || rawL >= 10 || rawU >= 10) {
    var iL = _stripToIntegerNoDecimals(rawL);
    var iU = _stripToIntegerNoDecimals(rawU);
    if (iU < iL) {
      return _applyOneRules(
        rawL,
        rawU,
        (min: iL.toDouble(), max: iL.toDouble()),
      );
    }
    final r = _gridFromPositiveInts(iL, iU);
    pair = (min: r.$1, max: r.$2);
  } else {
    pair = (min: _decadeLower(rawL), max: _decadeUpper(rawU));
  }

  var minB = pair.min;
  var maxB = pair.max;
  if (minCap != null && minB < minCap) minB = minCap;
  if (maxCap != null && maxB > maxCap) maxB = maxCap;
  if (maxB < minB) maxB = minB;

  return _applyOneRules(rawL, rawU, (min: minB, max: maxB));
}

/// `envelopeSliderBoundsForCenter( v )` is **convenience only**: it sets
/// `rawL = 0.5 v`, `rawU = 1.5 v` and passes the same rules + tier clamps.
({double min, double max}) envelopeSliderBoundsForCenter(double v) {
  if (v.isNaN || v.isInfinite) return (min: 0, max: 0);
  if (v < 0) v = 0;
  if (v == 0) return (min: 0, max: 0);

  final rawL = 0.5 * v;
  final rawU = 1.5 * v;

  if (v < 1) {
    return envelopeSliderBoundsFromRaws(
      rawL,
      rawU,
      minCap: 0,
      maxCap: 1,
    );
  }
  if (v < 10) {
    return envelopeSliderBoundsFromRaws(
      rawL,
      rawU,
      minCap: 0,
      maxCap: 10,
    );
  }
  return envelopeSliderBoundsFromRaws(rawL, rawU);
}

double _decadeLower(double x) {
  if (x <= 0) return 0;
  if (x.isNaN) return 0;
  if (x < 1e-10) return 0;
  final l = math.log(x) / math.ln10;
  return math.pow(10, l.floor()).toDouble();
}

/// Smallest `10^k` with `k` integer and `10^k >= x` (x > 0).
double _decadeUpper(double x) {
  if (x <= 0) return 0;
  if (x.isNaN) return 0;
  final l = math.log(x) / math.ln10;
  return math.pow(10, l.ceil()).toDouble();
}

(double, double) _gridFromPositiveInts(int iL, int iU) {
  if (iL < 0) iL = 0;
  if (iU < iL) {
    return (iL.toDouble(), iL.toDouble());
  }
  final dL = _decimalDigitCountForPositiveInt(iL);
  final dU = _decimalDigitCountForPositiveInt(iU);
  final d = math.min(dL, dU);
  final step = math.pow(10, d - 1).toDouble();
  var minB = (iL / step).floor() * step;
  var maxB = (iU / step).ceil() * step;
  if (maxB < minB) maxB = minB;
  return (minB.toDouble(), maxB.toDouble());
}

int _decimalDigitCountForPositiveInt(int n) {
  var k = n;
  if (k < 0) k = -k;
  if (k == 0) return 1;
  return k.toString().length;
}

int _stripToIntegerNoDecimals(double raw) {
  if (raw.isNaN) return 0;
  if (raw >= 0) return raw.truncate();
  return raw.ceil();
}

({double min, double max}) _applyOneRules(
  double rawL,
  double rawU,
  ({double min, double max}) pair,
) {
  var min = pair.min;
  var max = pair.max;
  if (isCloseTo(rawL, 1)) {
    min = 0;
  }
  if (isCloseTo(rawU, 1)) {
    max = 1;
  }
  if (max < min) {
    max = min;
  }
  return (min: min, max: max);
}

bool valueFitsInBounds(
  double value,
  double min,
  double max, {
  double eps = 1e-6,
}) {
  if (value < min - eps) return false;
  if (value > max + eps) return false;
  return true;
}
