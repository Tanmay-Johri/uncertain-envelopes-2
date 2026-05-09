import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'version_poller.dart';

/// Reads `games.state_version` from Postgres for the version-poller repair
/// path when Redis is missing or stale (B-GAP-3b).
///
/// On any error (RLS, network, malformed row), returns `null` so
/// [CompositeVersionPoller] can degrade without throwing.
class SupabaseVersionQuery implements SupabaseVersionReader {
  /// Production path: uses [client]'s PostgREST stack.
  SupabaseVersionQuery(SupabaseClient client)
      : _client = client,
        _fetchOverride = null;

  /// Test seam: bypasses the client and uses [fetch] as the row source.
  @visibleForTesting
  SupabaseVersionQuery.withFetch(
    Future<Map<String, dynamic>?> Function(String gameId) fetch,
  )  : _client = null,
        _fetchOverride = fetch;

  final SupabaseClient? _client;
  final Future<Map<String, dynamic>?> Function(String gameId)? _fetchOverride;

  static int? _coerceVersion(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  @override
  Future<int?> readVersion(String gameId) async {
    try {
      final Map<String, dynamic>? row;
      if (_fetchOverride != null) {
        row = await _fetchOverride(gameId);
      } else {
        row = await _client!
            .from('games')
            .select('state_version')
            .eq('game_id', gameId)
            .maybeSingle();
      }
      if (row == null) return null;
      return _coerceVersion(row['state_version']);
    } catch (_) {
      return null;
    }
  }
}
