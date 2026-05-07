abstract final class AppConstants {
  // Supabase
  static const supabaseUrl = 'https://agohjlgjjxbtfjdgqixa.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFnb2hqbGdqanhidGZqZGdxaXhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2NzYyNTgsImV4cCI6MjA5MjI1MjI1OH0.4hSTPRg5dOzAQNpl-A82Ru8YO9xGT7cqSrMh9YW3tOo';

  // Upstash Redis (REST API)
  static const upstashRedisUrl = 'https://becoming-toad-92614.upstash.io';
  static const upstashRedisToken =
      'gQAAAAAAAWnGAAIncDI2NWZmYzkzOWJmMTY0NDc0YTUxNmNhZjE3NjY3NTJjNHAyOTI2MTQ';

  // Account constraints
  static const minUsernameLength = 3;
  static const maxUsernameLength = 32;
  static const minPasswordLength = 8;

  // Game constraints
  static const maxGameNameLength = 32;
  static const maxGameDescriptionLength = 256;
  static const minMaxPlayers = 1;
  static const maxMaxPlayers = 128;
  static const joiningCodeLength = 5;
  static const maxCommandRetries = 3;
  static const sweeperIntervalSeconds = 10;
  static const staleClaimThresholdSeconds = 30;
  static const versionPollIntervalSeconds = 5;

  /// Max wait for backend ack that a `cancel_order` **command row** was created.
  /// If this elapses, UI reverts from **Cancelling** and shows a small banner.
  static const cancelOrderCommandAckTimeout = Duration(seconds: 10);

  // App metadata
  static const appTitle = 'uncertain-envelopes-2';
}
