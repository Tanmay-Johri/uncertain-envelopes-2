import 'dart:math' as math;

import 'envelope_value_parse.dart' show isCloseTo;

/// **±50%** of [v] as raw min/max, then “nice” bounds: strip decimals, take
/// [min] digit count of the two [raw] integers, set grid step to **10⁽ᵈ⁻¹⁾**,
/// floor the **lower** bound and **ceil** the **upper** on that grid (C6 PnL).
({double min, double max}) envelopeSliderBoundsForCenter(double v) {
  if (v.isNaN || v.isInfinite) return (min: 0, max: 0);
  if (v < 0) v = 0;
  if (v == 0) return (min: 0, max: 0);

  final rawL = 0.5 * v;
  final rawU = 1.5 * v;
  if (v < 1) {
    return _applyOneRules(
      rawL,
      rawU,
      0,
      1,
    );
  }
  if (v < 10) {
    return _applyOneRules(
      rawL,
      rawU,
      0,
      10,
    );
  }
  // v >= 10: strip decimal places, then same grid step for both from
  // min(digits(lower), digits(upper)).
  final iL = _stripToIntegerNoDecimals(rawL);
  final iU = _stripToIntegerNoDecimals(rawU);
  if (iU < iL) {
    return _applyOneRules(rawL, rawU, iL.toDouble(), iL.toDouble());
  }
  final dL = _decimalDigitCountForPositiveInt(iL);
  final dU = _decimalDigitCountForPositiveInt(iU);
  final d = math.min(dL, dU);
  final step = math.pow(10, d - 1).toDouble();
  var minB = (iL / step).floor() * step;
  var maxB = (iU / step).ceil() * step;
  return _applyOneRules(rawL, rawU, minB, maxB);
}

/// After removing fraction, count decimal digits in [n] (e.g. 0→1, 7→1, 42→2).
int _decimalDigitCountForPositiveInt(int n) {
  var k = n;
  if (k < 0) k = -k;
  if (k == 0) return 1;
  return k.toString().length;
}

/// “Remove the decimal places” (toward zero for the magnitudes we use; [raw] >= 0).
int _stripToIntegerNoDecimals(double raw) {
  if (raw.isNaN) return 0;
  if (raw >= 0) return raw.truncate();
  return raw.ceil();
}

/// If raw lower is **exactly** 1, the displayed min is 0. If raw upper is
/// **exactly** 1, the cap can be 1. See product spec.
({double min, double max}) _applyOneRules(
  double rawL,
  double rawU,
  double minB,
  double maxB,
) {
  var min = minB;
  var max = maxB;
  if (isCloseTo(rawL, 1)) min = 0;
  if (isCloseTo(rawU, 1)) max = 1;
  if (max < min) max = min;
  return (min: min, max: max);
}

/// Whether [value] is inside **[min, max]** without recomputing bounds.
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
