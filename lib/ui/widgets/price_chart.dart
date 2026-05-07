import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/chart/chart_axis.dart';
import '../../core/chart/chart_tooltip_format.dart';
import '../../core/chart/price_chart_point.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'pulsing_live_dot.dart';

final _headerPriceFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);

final _axisPriceFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

double _xMinutes(Duration d) => d.inMicroseconds / (60 * 1000000.0);

class _SpotsBundle {
  const _SpotsBundle({required this.spots, required this.tooltipPoints});

  final List<FlSpot> spots;

  /// Parallel to [spots]: execution point shown when that spot is touched.
  final List<PriceChartPoint> tooltipPoints;
}

_SpotsBundle _buildSpotsBundle(
  List<PriceChartPoint> points,
  ChartAxisConfig axis,
) {
  final sorted = [...points]
    ..sort((a, b) => a.timeElapsed.compareTo(b.timeElapsed));
  if (sorted.isEmpty) {
    return const _SpotsBundle(spots: [], tooltipPoints: []);
  }
  if (sorted.length == 1) {
    final p = sorted.single;
    final x = _xMinutes(p.timeElapsed);
    final xR = math.max(x + 1e-6, axis.maxXMinutes * 0.02);
    return _SpotsBundle(
      spots: [FlSpot(x, p.price), FlSpot(xR, p.price)],
      tooltipPoints: [p, p],
    );
  }
  return _SpotsBundle(
    spots: sorted
        .map((p) => FlSpot(_xMinutes(p.timeElapsed), p.price))
        .toList(),
    tooltipPoints: sorted,
  );
}

double _spotToPixelX(double spotX, double width, double maxX) {
  if (maxX <= 0) return 0;
  return (spotX / maxX) * width;
}

double _spotToPixelY(
  double spotY,
  double height,
  double minY,
  double maxY,
) {
  final d = maxY - minY;
  if (d == 0) return height;
  return height - ((spotY - minY) / d) * height;
}

/// Inline label under the touched point (not fl_chart’s built-in tooltip).
class _HoverChip extends StatelessWidget {
  const _HoverChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.outlineSubtle.withValues(alpha: 0.9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: AppTypography.monoSmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _PriceChartPlot extends StatefulWidget {
  const _PriceChartPlot({
    required this.axis,
    required this.bundle,
    required this.gameStartedAtUtc,
    required this.localeTag,
  });

  final ChartAxisConfig axis;
  final _SpotsBundle bundle;
  final DateTime? gameStartedAtUtc;
  final String localeTag;

  @override
  State<_PriceChartPlot> createState() => _PriceChartPlotState();
}

class _PriceChartPlotState extends State<_PriceChartPlot> {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _chartLeafKey = GlobalKey();

  TouchLineBarSpot? _touchSpot;
  PriceChartPoint? _tooltipPoint;

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    if (!event.isInterestedForInteractions ||
        response?.lineBarSpots == null ||
        response!.lineBarSpots!.isEmpty) {
      if (_touchSpot != null) {
        setState(() {
          _touchSpot = null;
          _tooltipPoint = null;
        });
      }
      return;
    }

    final spot = response.lineBarSpots!.first;
    final p = widget.bundle.tooltipPoints[spot.spotIndex];
    setState(() {
      _touchSpot = spot;
      _tooltipPoint = p;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  LineChartData _lineData({
    required List<FlSpot> spots,
    required double minY,
    required double maxY,
    required FlLine gridLine,
    required double hInterval,
    required double vInterval,
  }) {
    return LineChartData(
      minX: 0,
      maxX: widget.axis.maxXMinutes,
      minY: minY,
      maxY: maxY,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: hInterval,
        verticalInterval: vInterval,
        getDrawingHorizontalLine: (_) => gridLine,
        getDrawingVerticalLine: (_) => gridLine,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        leftTitles: const AxisTitles(),
        bottomTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Minutes since game start',
              key: const ValueKey('price-chart-x-axis-caption'),
              style: AppTypography.monoSmall.copyWith(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          axisNameSize: 22,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: widget.axis.divisionMinutes.toDouble(),
            getTitlesWidget: (value, meta) {
              if (value < -0.01 || value > widget.axis.maxXMinutes + 0.01) {
                return const SizedBox.shrink();
              }
              final d = widget.axis.divisionMinutes;
              final tick = (value / d).round() * d;
              if ((value - tick).abs() > 0.06 * d) {
                return const SizedBox.shrink();
              }
              if (tick < 0 || tick > widget.axis.maxXMinutes + 0.01) {
                return const SizedBox.shrink();
              }
              return Text(
                '$tick',
                style: AppTypography.monoSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: hInterval,
            getTitlesWidget: (value, meta) {
              if (value < minY - 0.01 || value > maxY + 0.01) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _axisPriceFormat.format(value),
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: spots.isEmpty
          ? const LineTouchData(enabled: false)
          : LineTouchData(
              touchSpotThreshold: 36,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) =>
                    List<LineTooltipItem?>.filled(touchedSpots.length, null),
              ),
              touchCallback: _onTouch,
            ),
      lineBarsData: spots.isEmpty
          ? []
          : [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: AppColors.primary,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  checkToShowDot: (spot, barData) {
                    if (barData.spots.isEmpty) return false;
                    return spot.x == barData.spots.last.x;
                  },
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.primary,
                      strokeWidth: 0,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
    );
  }

  Widget _belowPointLabel() {
    final spot = _touchSpot;
    final point = _tooltipPoint;
    if (spot == null || point == null) return const SizedBox.shrink();

    final stackRo = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final leafRo =
        _chartLeafKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackRo == null || leafRo == null || !leafRo.hasSize) {
      return const SizedBox.shrink();
    }

    final w = leafRo.size.width;
    final h = leafRo.size.height;
    final px = _spotToPixelX(spot.x, w, widget.axis.maxXMinutes);
    final py = _spotToPixelY(
      spot.y,
      h,
      widget.axis.minPrice,
      widget.axis.maxPrice,
    );
    final anchor = stackRo.globalToLocal(
      leafRo.localToGlobal(Offset(px, py)),
    );

    final text = priceChartTooltipHoverLabel(
      gameStartedAtUtc: widget.gameStartedAtUtc,
      timeElapsed: point.timeElapsed,
      price: point.price,
      localeName: widget.localeTag,
      currencyFormat: _headerPriceFormat,
    );

    return Positioned(
      left: anchor.dx,
      top: anchor.dy + 6,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: IgnorePointer(
          child: _HoverChip(label: text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.bundle.spots;
    final minY = widget.axis.minPrice;
    final maxY = widget.axis.maxPrice;
    final gridLine = FlLine(
      color: Colors.white.withValues(alpha: 0.08),
      strokeWidth: 1,
    );
    final hInterval = (maxY - minY) / 4;
    final vInterval = widget.axis.divisionMinutes.toDouble();

    return Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        LineChart(
          _lineData(
            spots: spots,
            minY: minY,
            maxY: maxY,
            gridLine: gridLine,
            hInterval: hInterval,
            vInterval: vInterval,
          ),
          duration: Duration.zero,
          chartRendererKey: _chartLeafKey,
        ),
        _belowPointLabel(),
      ],
    );
  }
}

/// Plan **C6**: `LineChart` with area fill; **X** = minutes since game start (6 divisions),
/// **Y** = execution prices from [axis].
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.marketPrice,
    required this.points,
    required this.axis,
    this.gameStartedAtUtc,
    this.cardHeight = 192,
  });

  final double marketPrice;
  final List<PriceChartPoint> points;
  final ChartAxisConfig axis;

  /// UTC instant when trading started (Supabase truth); tooltip wall-clock only.
  final DateTime? gameStartedAtUtc;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    final bundle = _buildSpotsBundle(points, axis);
    final localeTag =
        Localizations.maybeLocaleOf(context)?.toLanguageTag() ?? 'en_US';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Market Price',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PulsingLiveDot(),
                  const SizedBox(width: 8),
                  Text(
                    _headerPriceFormat.format(marketPrice),
                    style: AppTypography.monoSmall.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          type: MaterialType.canvas,
          color: AppColors.surfaceContainerLow,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          clipBehavior: Clip.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.outline),
          ),
          child: SizedBox(
            height: cardHeight,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 4,
                top: 8,
                bottom: 8,
              ),
              child: _PriceChartPlot(
                axis: axis,
                bundle: bundle,
                gameStartedAtUtc: gameStartedAtUtc,
                localeTag: localeTag,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
