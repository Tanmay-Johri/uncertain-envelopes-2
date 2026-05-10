import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

/// PKCE/async storage backed by an in-memory map — no platform plugins.
///
/// Use via [supabaseAuthOptionsWithoutPlugins] in unit/widget tests where
/// [SharedPreferences] is unavailable.
final class MemoryGotrueAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> getItem({required String key}) async => _map[key];

  @override
  Future<void> removeItem({required String key}) async {
    _map.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _map[key] = value;
  }
}

/// Auth client options that do not touch [SharedPreferences] (VM tests).
FlutterAuthClientOptions supabaseAuthOptionsWithoutPlugins() {
  return FlutterAuthClientOptions(
    localStorage: const EmptyLocalStorage(),
    pkceAsyncStorage: MemoryGotrueAsyncStorage(),
  );
}

/// Initializes the global Supabase client used by repositories and realtime.
///
/// Safe to call more than once: [Supabase.initialize] skips when already
/// initialized (see package implementation).
///
/// In tests, pass [authOptions] from [supabaseAuthOptionsWithoutPlugins] so
/// initialization does not require the `shared_preferences` plugin.
Future<void> initializeSupabase({
  FlutterAuthClientOptions? authOptions,
}) async {
  if (authOptions != null) {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      debug: kDebugMode,
      authOptions: authOptions,
    );
  } else {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      debug: kDebugMode,
    );
  }
}

/// Whether [Supabase.initialize] has completed in this isolate.
///
/// Unlike [Supabase.instance] before initialization, this does not throw
/// (uses [AssertionError] from the package guard when init has not run).
bool get isSupabaseClientAvailable {
  try {
    return Supabase.instance.isInitialized;
  } on AssertionError {
    return false;
  }
}
