/// Compile-time backend selection (Phase 2C uses the live stack).
///
/// ```bash
/// flutter run --dart-define=USE_REAL_BACKEND=true
/// ```
const bool _useRealBackend = bool.fromEnvironment(
  'USE_REAL_BACKEND',
  defaultValue: false,
);

/// When `false` (default), repository [Provider]s return in-memory fakes so UI
/// wiring (Phase 2B) works offline. When `true`, repos use
/// `Supabase.instance.client` — call [initializeSupabase] before first read.
bool get useRealBackend => _useRealBackend;
