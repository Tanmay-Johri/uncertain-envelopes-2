import 'package:intl/intl.dart';

final _cashWholeUsd = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 0,
);

/// Cash line for stat tiles: positive shows `+$`; negative `-$`; zero `$0`.
String formatTradingDeltaCash(double v) {
  final n = v.round();
  if (n > 0) return '+${_cashWholeUsd.format(n)}';
  if (n < 0) return '-${_cashWholeUsd.format(n.abs())}';
  return _cashWholeUsd.format(0);
}

/// Envelope count: positive shows leading `+`; zero and negative unchanged.
String formatTradingDeltaEnvelopes(double v) {
  final n = v.round();
  if (n > 0) return '+$n';
  return '$n';
}

/// Whole-dollar display for the PnL line (tinted separately in the widget).
String formatProjectedPnl(double pnl) {
  return formatTradingDeltaCash(pnl);
}
