/// Phase 2 plan §2B.10 names a “game realtime service provider”.
///
/// Implementation: [gameRealtimeSessionProvider] in
/// `game_realtime_session_provider.dart` — one [GameRealtimeService] per
/// watched game id, started while watched and disposed on unwatch via
/// [bindGameRealtimeServiceToRef]. UI mounts
/// `GameRealtimeSessionScope` (see `lib/ui/widgets/game_realtime_session_scope.dart`).
library;

export '../services/game_realtime_session_binding.dart'
    show bindGameRealtimeServiceToRef;
export 'game_realtime_session_provider.dart';
