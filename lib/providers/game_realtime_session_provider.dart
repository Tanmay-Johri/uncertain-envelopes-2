import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../bootstrap/supabase_bootstrap.dart';
import '../core/constants/app_constants.dart';
import '../services/game_realtime_service.dart';
import '../services/game_realtime_session_binding.dart';
import '../services/riverpod_realtime_target.dart';
import '../services/supabase_realtime_subscriber.dart';
import 'trading_provider.dart';
import '../services/supabase_version_query.dart';
import '../services/version_poller.dart';
import '_environment.dart';

part 'game_realtime_session_provider.g.dart';

/// Starts [GameRealtimeService] for [gameId] while this provider is watched,
/// and disposes it when no longer watched.
///
/// No-op when [useRealBackend] is `false` (default in-memory stack), when
/// [gameId] is empty, or when Supabase has not finished initializing.
@riverpod
void gameRealtimeSession(Ref ref, String gameId) {
  if (!useRealBackend) return;
  if (gameId.isEmpty) return;
  if (!isSupabaseClientAvailable) return;

  ref.watch(pendingCreateOrderCommandsProvider(gameId));

  final target = RiverpodRealtimeTarget(ref: ref, gameId: gameId);
  final subscriber = SupabaseRealtimeSubscriber(Supabase.instance.client);
  final poller = CompositeVersionPoller(
    redis: UpstashRedisVersionReader(
      url: AppConstants.upstashRedisUrl,
      token: AppConstants.upstashRedisToken,
    ),
    supabase: SupabaseVersionQuery(Supabase.instance.client),
  );

  final service = GameRealtimeService(
    gameId: gameId,
    target: target,
    subscriber: subscriber,
    poller: poller,
    pollInterval: Duration(seconds: AppConstants.versionPollIntervalSeconds),
  );

  bindGameRealtimeServiceToRef(ref, service);
}
