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

/// Shown when a USD money line has no resolved value (envelope / PnL pending).
const String kUnsetUsdLine = r'$—';

/// Whole-dollar display for the PnL line (tinted separately in the widget).
String formatProjectedPnl(double pnl) {
  return formatTradingDeltaCash(pnl);
}

/// PnL column when backend has not applied an envelope snapshot yet.
String formatResultsPnlPlaceholder(double? pnl) {
  if (pnl == null) return kUnsetUsdLine;
  return formatProjectedPnl(pnl);
}

/// Wall-clock time for the transaction log (matches chart tooltip local clock).
///
/// [executedAtUtc] is stored as UTC from the backend; displayed in the user's
/// local timezone.
String formatTradeLogTime(DateTime executedAtUtc, {required String localeName}) {
  return DateFormat.Hm(localeName).format(executedAtUtc.toLocal());
}
