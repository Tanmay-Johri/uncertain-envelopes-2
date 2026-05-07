import 'package:flutter/material.dart';

/// Displays a stored **`createdAt` instant as UTC** in the user's **local**
/// timezone using [MaterialLocalizations] (calendar + clock style matched to
/// the same settings as Flutter pickers—not a hard-coded `intl` skeleton that
/// can disagree with Web/desktop locale).
///
/// Result shape: **`May 3, 2026 · 3:30 PM`** (weekday omitted; exact tokens depend on
/// locale and 12/24h preference via [MediaQuery]).
String formatOrderCreatedUtcForUi(BuildContext context, DateTime createdAtUtc) {
  final local = createdAtUtc.toLocal();
  final ml = MaterialLocalizations.of(context);
  final clock = TimeOfDay.fromDateTime(local);
  final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
  return '${ml.formatShortDate(local)} · '
      '${ml.formatTimeOfDay(clock, alwaysUse24HourFormat: use24Hour)}';
}
