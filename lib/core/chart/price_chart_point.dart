import 'package:flutter/foundation.dart';

/// One execution sample for the price chart (plan **B9** `executionHistoryProvider`).
@immutable
class PriceChartPoint {
  const PriceChartPoint({required this.timeElapsed, required this.price});

  final Duration timeElapsed;
  final double price;
}
