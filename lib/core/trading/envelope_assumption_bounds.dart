import 'dart:math' as math;

import 'envelope_value_parse.dart' show isCloseTo;

/// “Nice” slider endpoints from a **(raw lower, raw upper)** half-range pair
/// (no required center [v]).
///
/// **Math (per your examples):** treat each end separately.
///
/// - **(0, 1)**: the unit band before any 10, 100, … grid:
///   - **lower** in `(0, 1) →` nice lower **`0`**
///   - **upper** in `(0, 1) →` nice upper **`1`**
///   (e.g. `0.65` → L\* `0`, U\* `1`.)
/// - **\[1, 10)** (not a power of 10 yet for the *upper* in the 1.25 case):
///   - **lower** `L → floor(L)` (e.g. `1.25 → 1`.)
///   - **upper** `U →` **smallest power of ten** `≥ U` (e.g. `1.25 → 10`.)
/// - **\[10, 100)**: **step 10** — `L → floor(L/10)·10`, `U → ceil(U/10)·10`
///   (e.g. `19 →` `10` and `20` from lower vs upper. `75 → 70`.)
/// - **\[100, 1000)`: **step 100** — `L → floor(L/100)·100`, `U → ceil(U/100)·100`
///   (e.g. `225 → 300`.)
/// - For **larger** [x] the same idea: one step `s = 10^k` from the bracket, round
///   **down** the lower and **up** the upper on that step — except the `(0,1)`,
///   `[1,10)` (upper) and `x≥1` (lower) rules above.
/// Together: `75, 225 → 70, 300` (not `70, 230`).
///
/// [envelopeSliderBoundsForCenter] is only **convenience**:
/// `L = 0.5v`, `U = 1.5v`, then optional UI clamp to `[0,1]` / `[0,10]`.
({double min, double max}) envelopeSliderBoundsFromRaws(
  double rawL,
  double rawU, {
  double? minCap,
  double? maxCap,
}) {
  if (rawL.isNaN || rawU.isNaN) return (min: 0, max: 0);
  if (rawL < 0) rawL = 0;
  if (rawU < 0) rawU = 0;
  if (rawU < rawL) {
    final t = rawL;
    rawL = rawU;
    rawU = t;
  }

  var minB = _niceLower(rawL);
  var maxB = _niceUpper(rawU);
  if (minCap != null && minB < minCap) minB = minCap;
  if (maxCap != null && maxB > maxCap) maxB = maxCap;
  if (maxB < minB) maxB = minB;

  return _applyOneRules(rawL, rawU, (min: minB, max: maxB));
}

/// `rawL = 0.5 v`, `rawU = 1.5 v`, then the same [envelopeSliderBoundsFromRaws],
/// with tier caps when [v] is in `(0,1)` or `[1,10)`.
({double min, double max}) envelopeSliderBoundsForCenter(double v) {
  if (v.isNaN || v.isInfinite) return (min: 0, max: 0);
  if (v < 0) v = 0;
  if (v == 0) return (min: 0, max: 0);

  final rawL = 0.5 * v;
  final rawU = 1.5 * v;

  if (v < 1) {
    return envelopeSliderBoundsFromRaws(rawL, rawU, minCap: 0, maxCap: 1);
  }
  if (v < 10) {
    return envelopeSliderBoundsFromRaws(rawL, rawU, minCap: 0, maxCap: 10);
  }
  return envelopeSliderBoundsFromRaws(rawL, rawU);
}

/// Nice **lower** tick for one raw (half-range) value.
double _niceLower(double x) {
  if (x <= 0) return 0;
  if (x.isNaN) return 0;
  if (x < 1) {
    return 0;
  }
  if (x < 10) {
    return x.floorToDouble();
  }
  if (x < 100) {
    return (x / 10).floor() * 10.0;
  }
  if (x < 1000) {
    return (x / 100).floor() * 100.0;
  }
  final s = math.pow(10, (math.log(x) / math.ln10).floor()).toDouble();
  return (x / s).floor() * s;
}

/// Nice **upper** tick for one raw (half-range) value.
double _niceUpper(double x) {
  if (x <= 0) return 0;
  if (x.isNaN) return 0;
  if (x < 1) {
    return 1;
  }
  if (x < 10) {
    if (x <= 1) {
      return 1;
    }
    return math.pow(10, (math.log(x) / math.ln10).ceil()).toDouble();
  }
  if (x < 100) {
    return (x / 10).ceil() * 10.0;
  }
  if (x < 1000) {
    return (x / 100).ceil() * 100.0;
  }
  final s = math.pow(10, (math.log(x) / math.ln10).floor()).toDouble();
  return (x / s).ceil() * s;
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
