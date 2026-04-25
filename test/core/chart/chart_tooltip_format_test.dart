import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:uncertain_envelopes_2/core/chart/chart_tooltip_format.dart';

void main() {
  group('priceChartTooltipHoverLabel', () {
    test('uses local hour:minute and price when game start is known', () {
      final start = DateTime.utc(2026, 4, 10, 14, 0, 0);
      const elapsed = Duration(minutes: 33);
      final fmt = NumberFormat.currency(locale: 'en_US', symbol: r'$');
      final timePart = DateFormat('h:mm a', 'en_US').format(
        start.toUtc().add(elapsed).toLocal(),
      );
      expect(
        priceChartTooltipHoverLabel(
          gameStartedAtUtc: start,
          timeElapsed: elapsed,
          price: 150.25,
          localeName: 'en_US',
          currencyFormat: fmt,
        ),
        '$timePart · ${fmt.format(150.25)}',
      );
    });

    test('when start is null, uses compact elapsed + price', () {
      final fmt = NumberFormat.currency(locale: 'en_US', symbol: r'$');
      expect(
        priceChartTooltipHoverLabel(
          gameStartedAtUtc: null,
          timeElapsed: const Duration(minutes: 12),
          price: 10,
          localeName: 'en_US',
          currencyFormat: fmt,
        ),
        '12m · ${fmt.format(10)}',
      );
    });

    test('when start is null, fractional minutes use one decimal', () {
      final fmt = NumberFormat.currency(locale: 'en_US', symbol: r'$');
      expect(
        priceChartTooltipHoverLabel(
          gameStartedAtUtc: null,
          timeElapsed: const Duration(seconds: 90),
          price: 1,
          localeName: 'en_US',
          currencyFormat: fmt,
        ),
        '1.5m · ${fmt.format(1)}',
      );
    });
  });
}
