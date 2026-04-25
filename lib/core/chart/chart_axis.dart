import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'price_chart_point.dart';

/// Horizontal division size in minutes per plan **B9** / **C6**.
int chartDivisionMinutesFromElapsed(Duration elapsed) {
  final t = elapsed.inMinutes;
  if (t < 6) return 1;
  if (t < 12) return 2;
  if (t < 18) return 3;
  if (t < 24) return 4;
  if (t < 30) return 5;
  if (t < 60) return 10;
  if (t < 120) return 20;
  if (t < 180) return 30;
  if (t < 240) return 40;
  return 60;
}

double _minutesSinceStart(Duration d) => d.inMicroseconds / (60 * 1000000.0);

/// Horizontal span is at least **six** intervals of [divisionMinutes] (ticks 0, d, …, 6d); Y from prices + padding.
@immutable
class ChartAxisConfig {
  const ChartAxisConfig({
    required this.divisionMinutes,
    required this.maxXMinutes,
    required this.minPrice,
    required this.maxPrice,
  });

  final int divisionMinutes;
  final double maxXMinutes;
  final double minPrice;
  final double maxPrice;

  factory ChartAxisConfig.fromExecutionHistory({
    required Duration sessionElapsed,
    required List<PriceChartPoint> points,
  }) {
    final division = chartDivisionMinutesFromElapsed(sessionElapsed);
    // Always reserve the full six-division width (e.g. d=10 → 0…60), not 5*d.
    final defaultMaxX = 6.0 * division;
    final dataMaxX = points.isEmpty
        ? 0.0
        : points.map((p) => _minutesSinceStart(p.timeElapsed)).reduce(math.max);
    final maxX = math.max(defaultMaxX, dataMaxX * 1.02);

    if (points.isEmpty) {
      return ChartAxisConfig(
        divisionMinutes: division,
        maxXMinutes: math.max(maxX, division.toDouble()),
        minPrice: 0,
        maxPrice: 1,
      );
    }
    final prices = points.map((p) => p.price).toList();
    final mn = prices.reduce(math.min);
    final mx = prices.reduce(math.max);
    var pad = (mx - mn) * 0.12;
    if (pad < 0.5) pad = 0.5;
    return ChartAxisConfig(
      divisionMinutes: division,
      maxXMinutes: maxX,
      minPrice: mn - pad,
      maxPrice: mx + pad,
    );
  }
}
