import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/chart/chart_axis.dart';
import 'package:uncertain_envelopes_2/core/chart/price_chart_point.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/price_chart.dart';

void main() {
  group('PriceChart', () {
    testWidgets('renders header, LineChart, and minute axis labels', (
      tester,
    ) async {
      const points = <PriceChartPoint>[
        PriceChartPoint(timeElapsed: Duration(minutes: 0), price: 148),
        PriceChartPoint(timeElapsed: Duration(minutes: 25), price: 150),
      ];
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 25),
        points: points,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PriceChart(marketPrice: 150, points: points, axis: axis),
          ),
        ),
      );
      expect(find.text('Market Price'), findsOneWidget);
      expect(find.text(r'$150.00'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      expect(
        find.byKey(const ValueKey('price-chart-x-axis-caption')),
        findsOneWidget,
      );
      expect(find.text('Minutes since game start'), findsOneWidget);
    });

    testWidgets('single point does not throw', (tester) async {
      const points = [
        PriceChartPoint(timeElapsed: Duration(minutes: 5), price: 42.5),
      ];
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 5),
        points: points,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PriceChart(marketPrice: 42.5, points: points, axis: axis),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows 60 on X axis for 10-minute divisions (six intervals)', (tester) async {
      const points = <PriceChartPoint>[
        PriceChartPoint(timeElapsed: Duration.zero, price: 148),
        PriceChartPoint(timeElapsed: Duration(minutes: 55), price: 150),
      ];
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 55),
        points: points,
      );
      expect(axis.divisionMinutes, 10);
      expect(axis.maxXMinutes, greaterThanOrEqualTo(60));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PriceChart(
              marketPrice: 150,
              points: points,
              axis: axis,
            ),
          ),
        ),
      );
      expect(find.text('60'), findsWidgets);
    });

    testWidgets('null market price shows hyphen in header', (tester) async {
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: Duration.zero,
        points: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PriceChart(
              marketPrice: null,
              points: const [],
              axis: axis,
            ),
          ),
        ),
      );
      expect(find.text('-'), findsOneWidget);
      expect(find.text(r'$150.00'), findsNothing);
    });

    testWidgets('empty history shows grid only', (tester) async {
      final axis = ChartAxisConfig.fromExecutionHistory(
        sessionElapsed: const Duration(minutes: 3),
        points: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: PriceChart(marketPrice: 0, points: const [], axis: axis),
          ),
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData, isEmpty);
    });
  });
}
