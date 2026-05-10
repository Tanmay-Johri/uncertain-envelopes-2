import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'price_chart_point.dart';

/// One vertex of the price line (one point per **integer minute** in range).
@immutable
class PriceChartSpotRow {
  const PriceChartSpotRow({
    required this.xMinutes,
    required this.y,
    this.tooltipExecution,
  });

  /// Whole minutes since game start (0, 1, 2, …). Adjacent minutes are
  /// connected with a straight segment — **diagonal** if [y] changed, flat if
  /// the forward-filled price stayed the same.
  final double xMinutes;
  final double y;

  /// Set only for minutes that had a trade; forward-filled minutes are `null`
  /// so hover only shows execution tooltips.
  final PriceChartPoint? tooltipExecution;
}

/// Sort [points] by time; last execution in a minute wins that bucket.
///
/// [v] forward-fills the last trade through each whole minute to [endMinute].
/// Emits one vertex per minute in `[firstMin .. endMinute]`, so the segment
/// from minute *m* to *m+1* is a straight line (diagonal when price moves at
/// *m+1*, horizontal when the carried price is unchanged).
List<PriceChartSpotRow> buildPriceChartStepRows({
  required List<PriceChartPoint> points,
  required double axisMaxXMinutes,
  required Duration chartSessionElapsed,
}) {
  if (points.isEmpty) return const [];

  final sorted = [...points]
    ..sort((a, b) => a.timeElapsed.compareTo(b.timeElapsed));

  final byMinute = <int, PriceChartPoint>{};
  for (final p in sorted) {
    final m = p.timeElapsed.inMinutes;
    byMinute[m] = p;
  }

  final firstMin = byMinute.keys.reduce(math.min);
  final lastTradeMin = byMinute.keys.reduce(math.max);

  final sessionEndMin = chartSessionElapsed.inMinutes;
  final axisCap = axisMaxXMinutes.ceil().clamp(0, 1 << 30);
  var endMinute = math.min(
    axisCap,
    math.max(sessionEndMin, lastTradeMin),
  );
  if (endMinute < firstMin) endMinute = firstMin;

  double? carry;
  final v = <int, double>{};
  for (var m = firstMin; m <= endMinute; m++) {
    if (byMinute.containsKey(m)) {
      carry = byMinute[m]!.price;
    }
    if (carry != null) {
      v[m] = carry;
    }
  }

  if (v.isEmpty) return const [];

  final rows = <PriceChartSpotRow>[];
  for (var m = firstMin; m <= endMinute; m++) {
    final y = v[m];
    if (y == null) continue;
    rows.add(
      PriceChartSpotRow(
        xMinutes: m.toDouble(),
        y: y,
        tooltipExecution: byMinute[m],
      ),
    );
  }

  if (rows.length == 1) {
    final only = rows.single;
    final ext = math.max(
      only.xMinutes + 1e-6,
      axisMaxXMinutes * 0.02,
    );
    rows.add(
      PriceChartSpotRow(
        xMinutes: ext,
        y: only.y,
        tooltipExecution: null,
      ),
    );
  }

  return rows;
}
