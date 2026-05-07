import 'package:intl/intl.dart';

final _localClockFmt = DateFormat.jm('en_US');
final _calendarDateFmt = DateFormat.yMMMd('en_US');

/// Calendar branch: [DateFormat.yMMMd] + literal ` at ` + [DateFormat.jm] (en_US).
///
/// A single combined ICU pattern is unsafe here: pattern letters like `j`/`m`/`M`
/// interact and can render garbage (e.g. `2026May3 at j35`) in `package:intl`.
String _calendarDateAtClock(DateTime createdAt) {
  final local = createdAt.toLocal();
  final date = _calendarDateFmt.format(local);
  final clock = _localClockFmt.format(local);
  return '$date at $clock';
}

String _clauseWithClock(String clause, DateTime createdAt) {
  final local = createdAt.toLocal();
  final clock = _localClockFmt.format(local);
  return '$clause · $clock';
}

/// Relative-ish label for the **Placed:** line (`admin_game_trading_dashboard_4`).
///
/// Appends wall-clock (**`· h:mm AM`** in en_US skeleton) relative to each case.
/// Pure function so tests pin [now]; the clock mirrors [DateTime.toLocal].
String pendingOrderPlacedLabel({
  required DateTime? createdAt,
  required DateTime now,
}) {
  if (createdAt == null) return '—';
  final createdUtc = createdAt.toUtc();
  final nowUtc = now.toUtc();
  final d = nowUtc.difference(createdUtc);
  if (d.isNegative || d.inDays >= 14) {
    return _calendarDateAtClock(createdAt);
  }
  if (d.inSeconds < 45) {
    return _clauseWithClock('just now', createdAt);
  }
  if (d.inMinutes < 60) {
    return _clauseWithClock('${d.inMinutes}m ago', createdAt);
  }
  if (d.inHours < 24) {
    return _clauseWithClock('${d.inHours}h ago', createdAt);
  }
  return _clauseWithClock('${d.inDays}d ago', createdAt);
}
