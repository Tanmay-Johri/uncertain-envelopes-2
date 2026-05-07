import 'package:intl/intl.dart';

/// Single-line hover label: local **hour:minute** (when [gameStartedAtUtc] is set)
/// and formatted **price**; otherwise elapsed time + price.
String priceChartTooltipHoverLabel({
  required DateTime? gameStartedAtUtc,
  required Duration timeElapsed,
  required double price,
  required String localeName,
  required NumberFormat currencyFormat,
}) {
  final timePart = gameStartedAtUtc != null
      ? DateFormat('h:mm a', localeName).format(
          gameStartedAtUtc.toUtc().add(timeElapsed).toLocal(),
        )
      : _elapsedShort(timeElapsed);
  return '$timePart · ${currencyFormat.format(price)}';
}

String _elapsedShort(Duration timeElapsed) {
  final minutes = timeElapsed.inMicroseconds / (60 * 1000000.0);
  final rounded = minutes.round();
  if ((minutes - rounded).abs() < 1e-9) {
    return '${rounded}m';
  }
  return '${minutes.toStringAsFixed(1)}m';
}
