import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/chart/chart_axis.dart';
import 'package:uncertain_envelopes_2/core/chart/price_chart_point.dart';
import 'package:uncertain_envelopes_2/core/chart/price_chart_step_series.dart';

void main() {
  group('buildPriceChartStepRows', () {
    test('forward-fills per minute; one vertex per minute; tooltips on trades only',
        () {
      final points = [
        PriceChartPoint(timeElapsed: Duration(minutes: 4), price: 100),
        PriceChartPoint(timeElapsed: Duration(minutes: 5), price: 101),
        PriceChartPoint(timeElapsed: Duration(minutes: 11), price: 99),
        PriceChartPoint(timeElapsed: Duration(minutes: 13), price: 100),
      ];
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 13),
        points: points,
      );
      final rows = buildPriceChartStepRows(
        points: points,
        axisMaxXMinutes: axis.maxXMinutes,
        chartSessionElapsed: const Duration(minutes: 13),
      );

      expect(rows.length, 13 - 4 + 1);
      expect(
        rows.map((r) => r.xMinutes).toList(),
        List<double>.generate(10, (i) => (4 + i).toDouble()),
      );
      expect(
        rows.firstWhere((r) => r.xMinutes == 6.0).y,
        101,
        reason: 'minute 6 carries 101 from trade at 5',
      );
      expect(
        rows.firstWhere((r) => r.xMinutes == 6.0).tooltipExecution,
        isNull,
      );

      expect(
        rows.every((r) => r.xMinutes >= 4),
        isTrue,
        reason: 'no line before first trade minute',
      );

      final tradeTips = rows.where((r) => r.tooltipExecution != null).toList();
      expect(tradeTips.length, 4);
      expect(
        tradeTips.map((r) => r.tooltipExecution!.price).toList(),
        [100, 101, 99, 100],
      );
    });

    test('empty executions yields empty rows', () {
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 5),
        points: const [],
      );
      final rows = buildPriceChartStepRows(
        points: const [],
        axisMaxXMinutes: axis.maxXMinutes,
        chartSessionElapsed: const Duration(minutes: 5),
      );
      expect(rows, isEmpty);
    });

    test('adjacent minutes with different prices are two vertices (diagonal segment)',
        () {
      final points = [
        PriceChartPoint(timeElapsed: Duration(minutes: 1), price: 107.5),
        PriceChartPoint(timeElapsed: Duration(minutes: 2), price: 100),
      ];
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 3),
        points: points,
      );
      final rows = buildPriceChartStepRows(
        points: points,
        axisMaxXMinutes: axis.maxXMinutes,
        chartSessionElapsed: const Duration(minutes: 3),
      );
      expect(rows.length, 3 - 1 + 1);
      final m1 = rows.firstWhere((r) => r.xMinutes == 1.0);
      final m2 = rows.firstWhere((r) => r.xMinutes == 2.0);
      expect(m1.y, 107.5);
      expect(m2.y, 100);
      expect(m1.tooltipExecution, isNotNull);
      expect(m2.tooltipExecution, isNotNull);
    });
  });
}
