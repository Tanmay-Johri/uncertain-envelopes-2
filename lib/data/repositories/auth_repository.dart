import '../models/player.dart';

/// Base class for any error thrown by an [AuthRepository] implementation.
///
/// Concrete subclasses are narrow and stable so the UI can match on them
/// without parsing strings.
sealed class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

class AuthInvalidCredentialsException extends AuthException {
  const AuthInvalidCredentialsException()
      : super('Invalid email/username or password.');
}

class AuthEmailAlreadyInUseException extends AuthException {
  const AuthEmailAlreadyInUseException()
      : super('This email is already registered.');
}

class AuthUsernameAlreadyInUseException extends AuthException {
  const AuthUsernameAlreadyInUseException()
      : super('This username is already taken.');
}

class AuthUsernameNotFoundException extends AuthException {
  const AuthUsernameNotFoundException()
      : super('No player with that username.');
}

class AuthNotLoggedInException extends AuthException {
  const AuthNotLoggedInException() : super('No player is logged in.');
}

class AuthUnknownException extends AuthException {
  const AuthUnknownException(super.message, {this.cause});
  final Object? cause;
}

/// The contract that every auth repository implementation must honour.
///
/// Providers and services depend only on this abstract class, never on a
/// concrete backend. This keeps the rest of the app testable without a
/// Supabase client.
abstract class AuthRepository {
  /// Creates a new auth user AND the matching `players` row. Returns the
  /// resulting profile. Throws [AuthEmailAlreadyInUseException] or
  /// [AuthUsernameAlreadyInUseException] on conflict.
  Future<Player> signUp({
    required String email,
    required String password,
    required String username,
  });

  /// Logs in using either an email or a username. If [emailOrUsername]
  /// contains '@' it is treated as an email; otherwise the repository
  /// resolves the username to its email first. Throws
  /// [AuthInvalidCredentialsException] on failure.
  Future<Player> logIn({
    required String emailOrUsername,
    required String password,
  });

  /// Ends the current session. Safe to call when no session exists.
  Future<void> signOut();

  /// Returns the currently logged-in player's profile, or null if no one is
  /// logged in. Never throws for missing session; it only throws on I/O
  /// failure.
  Future<Player?> getCurrentPlayer();

  /// Deletes both the auth user and the `players` row. The session is
  /// invalidated as a side effect. Throws [AuthNotLoggedInException] if no
  /// session exists.
  Future<void> deleteAccount();

  /// Emits the current player (or null) whenever the auth state changes.
  /// Must emit the current value synchronously on subscription.
  Stream<Player?> watchCurrentPlayer();

  /// After a successful `players`-row mutation (e.g. username), adopt the
  /// updated profile into the session snapshot so [getCurrentPlayer] and
  /// streams stay coherent. In-memory: replaces cached [Player] when ids
  /// match. Supabase: no-op (next [getCurrentPlayer] reads Postgres).
  Future<void> adoptUpdatedProfile(Player player);
}
