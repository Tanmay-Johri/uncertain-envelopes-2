import 'package:flutter/foundation.dart';

/// Best-effort post-submit refresh for trading / orders flows.
///
/// Realtime is the primary delivery mechanism; explicit refreshes after
/// `submitCreateOrder` are only a low-latency UI bump. If any refresh throws,
/// we **must not** propagate so the caller does not show a false-positive
/// "Could not submit order" when the command succeeded.
Future<void> bestEffortPostSubmitRefresh(
  List<Future<void> Function()> refreshFns,
) async {
  try {
    await Future.wait(refreshFns.map((f) => f()));
  } catch (e, st) {
    debugPrint(
      'post-submit refresh failed (best-effort, ignored): $e\n$st',
    );
  }
}
