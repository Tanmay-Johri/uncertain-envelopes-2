/// Configuration for the trading price chart axes. The PRD (§B9 chart
/// rules) specifies exactly 6 horizontal divisions, with the interval
/// chosen from a fixed lookup. The vertical axis auto-scales to the
/// observed price range with small padding.
class ChartAxisConfig {
  const ChartAxisConfig({
    required this.divisionMinutes,
    required this.divisionCount,
    required this.totalElapsedSeconds,
    required this.minPrice,
    required this.maxPrice,
  });

  /// Minute interval between each vertical grid line on the time axis.
  /// Always one of [1, 2, 3, 4, 5, 10, 20, 30, 40, 60].
  final int divisionMinutes;

  /// Always 6 per PRD, kept as a field so a future design change does
  /// not require a PR against every consumer.
  final int divisionCount;

  /// Elapsed time the axis is covering, in seconds. Useful for the
  /// chart's own x-scale.
  final int totalElapsedSeconds;

  final double minPrice;
  final double maxPrice;

  /// Total axis length in minutes (divisionMinutes * divisionCount).
  int get totalAxisMinutes => divisionMinutes * divisionCount;

  @override
  bool operator ==(Object other) =>
      other is ChartAxisConfig &&
      other.divisionMinutes == divisionMinutes &&
      other.divisionCount == divisionCount &&
      other.totalElapsedSeconds == totalElapsedSeconds &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice;

  @override
  int get hashCode => Object.hash(
        divisionMinutes,
        divisionCount,
        totalElapsedSeconds,
        minPrice,
        maxPrice,
      );

  @override
  String toString() =>
      'ChartAxisConfig(divisionMinutes: $divisionMinutes, '
      'divisionCount: $divisionCount, '
      'elapsedSeconds: $totalElapsedSeconds, '
      'price: [$minPrice, $maxPrice])';
}

/// A single (timeElapsed, price) datapoint used by both
/// executionHistoryProvider and the chart widget. `timeElapsed` is
/// computed from `execution.executed_at - game.start_time`.
class ExecutionPoint {
  const ExecutionPoint({
    required this.timeElapsed,
    required this.price,
  });

  final Duration timeElapsed;
  final double price;

  @override
  bool operator ==(Object other) =>
      other is ExecutionPoint &&
      other.timeElapsed == timeElapsed &&
      other.price == price;

  @override
  int get hashCode => Object.hash(timeElapsed, price);

  @override
  String toString() =>
      'ExecutionPoint(${timeElapsed.inSeconds}s, $price)';
}

/// Pure function exposed so it can be tested in isolation from Riverpod.
/// Picks the first interval from [1, 2, 3, 4, 5, 10, 20, 30, 40, 60]
/// where `elapsed < interval * 6 minutes`. Falls back to 60 for very
/// long games so the axis never goes sub-second.
int pickDivisionMinutes(Duration elapsed) {
  const intervals = [1, 2, 3, 4, 5, 10, 20, 30, 40, 60];
  for (final interval in intervals) {
    if (elapsed.inSeconds < interval * 6 * 60) {
      return interval;
    }
  }
  return 60;
}
