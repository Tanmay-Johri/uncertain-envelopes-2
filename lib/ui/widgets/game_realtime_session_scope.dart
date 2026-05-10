import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_realtime_service_provider.dart';

/// Keeps [gameRealtimeSessionProvider] alive for [gameId] for the subtree.
///
/// Mount under a route whose `GoRouterState` exposes `pathParameters['id']`
/// for the active game.
class GameRealtimeSessionScope extends ConsumerWidget {
  const GameRealtimeSessionScope({
    super.key,
    required this.gameId,
    required this.child,
  });

  final String gameId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (gameId.isEmpty) return child;
    ref.watch(gameRealtimeSessionProvider(gameId));
    return child;
  }
}
