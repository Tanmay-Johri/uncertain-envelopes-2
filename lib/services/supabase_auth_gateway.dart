import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Narrow seam between [SupabaseAuthRepository] and the Supabase SDK.
///
/// The repository owns all business logic; the gateway only makes the raw
/// calls. This is what lets us unit-test the repository with a fake gateway
/// instead of mocking Supabase's fluent query builder.
abstract class SupabaseAuthGateway {
  /// Creates the auth user. Returns the new auth user id or throws
  /// [GatewayEmailInUseException].
  Future<String> createAuthUser({
    required String email,
    required String password,
  });

  /// Signs in with email + password. Returns the auth user id, or throws
  /// [GatewayInvalidCredentialsException].
  Future<String> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// The currently authenticated user id, or null.
  String? currentAuthUserId();

  /// Emits auth user id on every auth state change. Does NOT replay the
  /// current value; the repository replays it itself.
  Stream<String?> authUserIdChanges();

  /// Inserts a row into `players`. Throws [GatewayUsernameInUseException]
  /// if the username already exists (unique constraint violation).
  Future<void> insertPlayerRow({
    required String playerId,
    required String email,
    required String username,
    required DateTime createdAt,
  });

  /// Fetches a `players` row by id, or null if not found.
  Future<Map<String, dynamic>?> fetchPlayerRow(String playerId);

  /// Looks up a player's email by username, or null if no such username.
  Future<String?> lookupEmailByUsername(String username);

  /// Deletes the currently authenticated player (both players row + auth
  /// user). Implemented server-side via RPC in the real impl.
  Future<void> deleteCurrentAccount();
}

sealed class GatewayException implements Exception {
  const GatewayException(this.message);
  final String message;
  @override
  String toString() => '$runtimeType($message)';
}

class GatewayEmailInUseException extends GatewayException {
  const GatewayEmailInUseException() : super('email_in_use');
}

class GatewayUsernameInUseException extends GatewayException {
  const GatewayUsernameInUseException() : super('username_in_use');
}

class GatewayInvalidCredentialsException extends GatewayException {
  const GatewayInvalidCredentialsException() : super('invalid_credentials');
}

/// Production implementation wrapping a real [sb.SupabaseClient].
class RealSupabaseAuthGateway implements SupabaseAuthGateway {
  RealSupabaseAuthGateway(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<String> createAuthUser({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      final user = res.user;
      if (user == null) {
        throw const GatewayInvalidCredentialsException();
      }
      return user.id;
    } on sb.AuthException catch (e) {
      if (e.message.toLowerCase().contains('already')) {
        throw const GatewayEmailInUseException();
      }
      rethrow;
    }
  }

  @override
  Future<String> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth
          .signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) {
        throw const GatewayInvalidCredentialsException();
      }
      return user.id;
    } on sb.AuthException {
      throw const GatewayInvalidCredentialsException();
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  String? currentAuthUserId() => _client.auth.currentUser?.id;

  @override
  Stream<String?> authUserIdChanges() =>
      _client.auth.onAuthStateChange.map((e) => e.session?.user.id);

  @override
  Future<void> insertPlayerRow({
    required String playerId,
    required String email,
    required String username,
    required DateTime createdAt,
  }) async {
    try {
      await _client.from('players').insert({
        'player_id': playerId,
        'email': email,
        'username': username,
        'created_at': createdAt.toUtc().toIso8601String(),
      });
    } on sb.PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const GatewayUsernameInUseException();
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchPlayerRow(String playerId) async {
    final row = await _client
        .from('players')
        .select()
        .eq('player_id', playerId)
        .maybeSingle();
    return row;
  }

  @override
  Future<String?> lookupEmailByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    try {
      final res = await _client.rpc<dynamic>(
        'lookup_player_email_by_username',
        params: {'p_username': normalized},
      );
      if (res == null) return null;
      return res as String;
    } on sb.PostgrestException {
      return null;
    }
  }

  @override
  Future<void> deleteCurrentAccount() async {
    await _client.rpc('delete_current_account');
  }
}
