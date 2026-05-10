import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_realtime_service.dart';

/// Starts [service] and disposes it when [ref] is disposed.
///
/// Centralises the Phase 2B.10 contract: one [GameRealtimeService] per
/// active watch, torn down when the owning provider element goes away so
/// channels and poll timers do not leak.
void bindGameRealtimeServiceToRef(Ref ref, GameRealtimeService service) {
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  unawaited(service.start());
}
