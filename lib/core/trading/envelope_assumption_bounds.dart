import 'dart:math' as math;

import 'envelope_value_parse.dart' show isCloseTo;

/// **±50%** of [v] as raw min/max, then “nice” bounds.
///
/// For **v < 1** and **1 ≤ v < 10**: find the smallest [p] (0…8) such that
/// [rawL] and [rawU] (±50% of [v]) round cleanly at scale `10^p`, build
/// integer grid `iL`/`iU`, take `d = min(digits(iL), digits(iU))`, `step` =
/// `10^(d-1)`, floor/ceil on that step, then scale back. Clamp the result to
/// `[0, 1]` or `[0, 10]`. Re-check [_applyOneRules] for the **≈1** special cases
/// (e.g. where raw hits **1.0** or **0.975**-style / **1.25**-style raw inputs).
///
/// For **v ≥ 10** (after the strict `<10` test): “remove decimals” = truncate to
/// integers, same digit grid, no tier clamp.
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
      _clampedGridFromRaws(
        rawL,
        rawU,
        minCap: 0,
        maxCap: 1,
      ),
    );
  }
  if (v < 10) {
    return _applyOneRules(
      rawL,
      rawU,
      _clampedGridFromRaws(
        rawL,
        rawU,
        minCap: 0,
        maxCap: 10,
      ),
    );
  }
  // v >= 10
  final iL = _stripToIntegerNoDecimals(rawL);
  final iU = _stripToIntegerNoDecimals(rawU);
  if (iU < iL) {
    return _applyOneRules(
      rawL,
      rawU,
      (min: iL.toDouble(), max: iL.toDouble()),
    );
  }
  final r = _gridFromPositiveInts(iL, iU);
  return _applyOneRules(rawL, rawU, (min: r.$1, max: r.$2));
}

/// Raw pair → (min, max) in original units, then clamped to
/// [ [minCap, maxCap] ].
({double min, double max}) _clampedGridFromRaws(
  double rawL,
  double rawU, {
  required double minCap,
  required double maxCap,
}) {
  final p = _smallestScaleP(rawL, rawU);
  final s = math.pow(10, p).toDouble();
  var iL = (rawL * s).round();
  var iU = (rawU * s).round();
  if (iU < iL) {
    final t = iL;
    iL = iU;
    iU = t;
  }
  final r = _gridFromPositiveInts(iL, iU);
  var minB = r.$1 / s;
  var maxB = r.$2 / s;
  if (minB < minCap) minB = minCap;
  if (maxB > maxCap) maxB = maxCap;
  if (maxB < minB) maxB = minB;
  return (min: minB, max: maxB);
}

/// Smallest [p] in 0…8 with round-trip error under `1e-3` in raw units
/// (after scaling) for both ends.
int _smallestScaleP(double rawL, double rawU) {
  for (var p = 0; p <= 8; p++) {
    final s = math.pow(10, p).toDouble();
    final iL = (rawL * s).round();
    final iU = (rawU * s).round();
    if ((iL / s - rawL).abs() > 1e-3) {
      continue;
    }
    if ((iU / s - rawU).abs() > 1e-3) {
      continue;
    }
    return p;
  }
  return 6;
}

/// [iL], [iU] positive integers; returns `(minB, maxB double)` as the grid.
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

/// Count decimal digits in a non-negative int (0→1, 7→1, 64→2).
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

/// If raw **lower** is **exactly** 1, the displayed min is 0. If raw **upper** is
/// **exactly** 1, the cap is 1 (even inside the 0–10 tier). See C6 PnL spec.
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
