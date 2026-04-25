import 'package:intl/intl.dart';

final _cashWholeUsd = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

/// Cash line for stat tiles: no leading `+`; negative shows `-` before `$`.
String formatTradingDeltaCash(double v) {
  final n = v.round();
  final body = _cashWholeUsd.format(n.abs());
  if (n < 0) return '-$body';
  return body;
}

/// Envelope count: integer string, no leading `+`.
String formatTradingDeltaEnvelopes(double v) => v.round().toString();
