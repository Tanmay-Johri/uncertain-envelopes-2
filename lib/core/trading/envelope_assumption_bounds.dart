import 'dart:math' as math;

/// Nice slider bounds from raw half-range **[rawL, rawU]** (typically `0.5·v` and
/// `1.5·v`) using [assumptionForStep] (the center) only to pick the tier and,
/// when `assumptionForStep >= 10`, the grid step:
///
/// - `0 < assumptionForStep < 1` → **(0, 1)** (raws ignored).
/// - `1 <= assumptionForStep < 10` → **(0, 10)** (raws ignored).
/// - `assumptionForStep >= 10` → `step = 10^floor(log10(v))`, then
///   `min = floor(rawL / step) * step`, `max = ceil(rawU / step) * step`
///   (stable via step-count floor/ceil).
({double min, double max}) envelopeSliderBoundsFromRaws(
  double rawL,
  double rawU, {
  required double assumptionForStep,
}) {
  if (rawL.isNaN || rawU.isNaN) return (min: 0, max: 0);
  if (assumptionForStep.isNaN || assumptionForStep.isInfinite) {
    return (min: 0, max: 0);
  }
  if (assumptionForStep < 0) assumptionForStep = 0;
  if (assumptionForStep == 0) return (min: 0, max: 0);

  if (assumptionForStep < 1) {
    return (min: 0, max: 1);
  }
  if (assumptionForStep < 10) {
    return (min: 0, max: 10);
  }

  if (rawL < 0) rawL = 0;
  if (rawU < 0) rawU = 0;
  if (rawU < rawL) {
    final t = rawL;
    rawL = rawU;
    rawU = t;
  }

  final step = _stepFromAssumption(assumptionForStep);
  if (step <= 0 || step.isNaN) {
    return (min: rawL, max: rawU);
  }

  final invStep = 1.0 / step;
  final minSteps = (rawL * invStep + 1e-12).floorToDouble();
  final maxSteps = (rawU * invStep - 1e-12).ceilToDouble();
  var minB = minSteps * step;
  var maxB = maxSteps * step;
  if (maxB < minB) maxB = minB;

  return (min: minB, max: maxB);
}

/// Convenience: `rawL = 0.5 v`, `rawU = 1.5 v`, [assumptionForStep] = `v`.
({double min, double max}) envelopeSliderBoundsForCenter(double v) {
  if (v.isNaN || v.isInfinite) return (min: 0, max: 0);
  if (v < 0) v = 0;
  if (v == 0) return (min: 0, max: 0);

  final rawL = 0.5 * v;
  final rawU = 1.5 * v;

  return envelopeSliderBoundsFromRaws(
    rawL,
    rawU,
    assumptionForStep: v,
  );
}

/// One grid step from the **envelope assumption** only (not from raw L/U).
double _stepFromAssumption(double v) {
  if (v <= 0 || v.isNaN) return 0;
  final k = (math.log(v) / math.ln10).floor();
  return math.pow(10, k).toDouble();
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
