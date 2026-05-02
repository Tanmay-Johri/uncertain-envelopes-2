import 'package:intl/intl.dart';

final _shortDateFmt = DateFormat.yMMMd('en_US');

/// Relative-ish label for the **Placed:** line (`admin_game_trading_dashboard_4`).
///
/// Pure function so tests can pin [now] (Stream C; Phase 2 may switch to device
/// locale rules).
String pendingOrderPlacedLabel({
  required DateTime? createdAt,
  required DateTime now,
}) {
  if (createdAt == null) return '—';
  final createdUtc = createdAt.toUtc();
  final nowUtc = now.toUtc();
  final d = nowUtc.difference(createdUtc);
  if (d.isNegative) {
    return _shortDateFmt.format(createdAt.toLocal());
  }
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 14) return '${d.inDays}d ago';
  return _shortDateFmt.format(createdAt.toLocal());
}
