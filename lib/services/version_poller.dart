import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads the `state_version` integer from the primary (Redis / Upstash)
/// cache. Returns null on miss OR when the source is unreachable — the
/// caller decides what to do with that signal.
abstract class RedisVersionReader {
  Future<int?> readVersion(String gameId);
}

/// Fallback: reads `games.state_version` directly from Postgres. Returns
/// null if the game row does not exist.
abstract class SupabaseVersionReader {
  Future<int?> readVersion(String gameId);
}

/// Combines both readers to give the service a single "what version is
/// authoritative right now" Future. Tries Redis first, then Supabase.
/// Returns null when both sources fail; the caller should log, but NOT
/// refresh, in that case.
abstract class VersionPoller {
  Future<int?> pollVersion(String gameId);
}

class CompositeVersionPoller implements VersionPoller {
  CompositeVersionPoller({
    required this.redis,
    required this.supabase,
  });

  final RedisVersionReader redis;
  final SupabaseVersionReader supabase;

  @override
  Future<int?> pollVersion(String gameId) async {
    try {
      final v = await redis.readVersion(gameId);
      if (v != null) return v;
    } catch (_) {
      // Redis unreachable — fall through to Supabase.
    }
    try {
      return await supabase.readVersion(gameId);
    } catch (_) {
      return null;
    }
  }
}

/// Reads `game_version:{gameId}` via the Upstash Redis REST API.
///
/// Upstash returns: `{"result": "<value-as-string>"}` or
/// `{"result": null}` for a miss. Non-200 responses are treated as
/// unreachable (-> null).
class UpstashRedisVersionReader implements RedisVersionReader {
  UpstashRedisVersionReader({
    required String url,
    required String token,
    http.Client? client,
  })  : _url = url,
        _token = token,
        _client = client ?? http.Client();

  final String _url;
  final String _token;
  final http.Client _client;

  @override
  Future<int?> readVersion(String gameId) async {
    final uri = Uri.parse('$_url/get/game_version:$gameId');
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final result = body['result'];
    if (result == null) return null;
    if (result is int) return result;
    if (result is String) return int.tryParse(result);
    return null;
  }
}
