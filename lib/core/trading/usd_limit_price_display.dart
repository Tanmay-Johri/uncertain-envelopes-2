import 'package:intl/intl.dart';

final _usd2Fmt = NumberFormat.currency(
  locale: 'en_US',
  symbol: r'$',
  decimalDigits: 2,
);

const _kCentEpsilon = 1e-6;

/// Limit price on active order cards: nearest-cent currency (two decimals) when
/// [price] lies on a cent; otherwise up to five fraction digits (trailing zeros
/// trimmed, minimum two fractional digits).
String formatUsdLimitForActiveOrder(double price) {
  if (price.isNaN || price.isInfinite) {
    return _usd2Fmt.format(0);
  }
  final cents = (price * 100).round();
  final onCent = (price - cents / 100.0).abs() <= _kCentEpsilon;
  if (onCent) {
    return _usd2Fmt.format(cents / 100.0);
  }
  final negative = price < 0;
  final p = negative ? -price : price;
  var s = p.toStringAsFixed(5);
  final dot = s.indexOf('.');
  if (dot < 0) {
    return negative ? '-\$$s' : '\$$s';
  }
  var intPart = s.substring(0, dot);
  var frac = s.substring(dot + 1);
  while (frac.length > 2 && frac.endsWith('0')) {
    frac = frac.substring(0, frac.length - 1);
  }
  final body = '\$$intPart.$frac';
  return negative ? '-$body' : body;
}
