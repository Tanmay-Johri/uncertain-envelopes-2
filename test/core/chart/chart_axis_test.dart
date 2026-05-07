import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/chart/chart_axis.dart';
import 'package:uncertain_envelopes_2/core/chart/price_chart_point.dart';

void main() {
  group('chartDivisionMinutesFromElapsed', () {
    test('3 min → 1 min divisions', () {
      expect(chartDivisionMinutesFromElapsed(const Duration(minutes: 3)), 1);
    });

    test('7 min → 2 min divisions', () {
      expect(chartDivisionMinutesFromElapsed(const Duration(minutes: 7)), 2);
    });

    test('25 min → 5 min divisions', () {
      expect(chartDivisionMinutesFromElapsed(const Duration(minutes: 25)), 5);
    });

    test('45 min → 10 min divisions', () {
      expect(chartDivisionMinutesFromElapsed(const Duration(minutes: 45)), 10);
    });

    test('150 min → 30 min divisions', () {
      expect(chartDivisionMinutesFromElapsed(const Duration(minutes: 150)), 30);
    });

    test('300 min → 60 min divisions', () {
      expect(chartDivisionMinutesFromElapsed(const Duration(minutes: 300)), 60);
    });
  });

  group('ChartAxisConfig.fromExecutionHistory', () {
    test('empty points still yields finite axis', () {
      final c = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 10),
        points: const [],
      );
      expect(c.divisionMinutes, 2);
      expect(c.maxXMinutes, greaterThan(0));
    });

    test('extends max X when last point exceeds default span', () {
      final c = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 55),
        points: const [
          PriceChartPoint(timeElapsed: Duration.zero, price: 100),
          PriceChartPoint(timeElapsed: Duration(minutes: 52), price: 101),
        ],
      );
      expect(c.maxXMinutes, greaterThanOrEqualTo(60));
      expect(c.minPrice, lessThan(100));
      expect(c.maxPrice, greaterThan(101));
    });

    test('10-minute divisions use full 0–60 minute span by default', () {
      final c = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 55),
        points: const [
          PriceChartPoint(timeElapsed: Duration(minutes: 55), price: 150),
        ],
      );
      expect(c.divisionMinutes, 10);
      expect(c.maxXMinutes, greaterThanOrEqualTo(60));
    });
  });
}
