import 'dart:math' as math;

import 'envelope_value_parse.dart' show isCloseTo;

/// **±50%** of [v] as raw min/max, then “nice” bounds for the range slider
/// and labels, using the tiering rules in the C6 PnL spec.
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
  // v >= 10
  final w = 0.1 * (rawU - rawL);
  if (w <= 0) {
    return _applyOneRules(rawL, rawU, rawL, rawU);
  }
  final logW = math.log(w) / math.ln10;
  final e = logW.isFinite ? logW.floor() : 0;
  final p = math.pow(10, e).toDouble();
  var minB = (rawL / p).floor() * p;
  var maxB = (rawU / p).ceil() * p;
  return _applyOneRules(rawL, rawU, minB, maxB);
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
