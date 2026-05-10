import 'dart:async';

import '../../services/supabase_auth_gateway.dart';
import '../models/player.dart';
import 'auth_repository.dart';

/// Concrete [AuthRepository] backed by Supabase (Auth + Postgres). The
/// repository owns all business logic (username-vs-email routing,
/// exception translation, profile fetch after auth); the [SupabaseAuthGateway]
/// seam owns all direct SDK calls.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseAuthGateway gateway,
    DateTime Function()? now,
  })  : _gateway = gateway,
        _now = now ?? DateTime.now;

  final SupabaseAuthGateway _gateway;
  final DateTime Function() _now;

  @override
  Future<Player> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim().toLowerCase();
    final String playerId;
    try {
      playerId = await _gateway.createAuthUser(
        email: normalizedEmail,
        password: password,
      );
    } on GatewayEmailInUseException {
      throw const AuthEmailAlreadyInUseException();
    }
    final createdAt = _now().toUtc();
    try {
      await _gateway.insertPlayerRow(
        playerId: playerId,
        email: normalizedEmail,
        username: normalizedUsername,
        createdAt: createdAt,
      );
    } on GatewayUsernameInUseException {
      throw const AuthUsernameAlreadyInUseException();
    }
    return Player(
      playerId: playerId,
      username: normalizedUsername,
      email: normalizedEmail,
      createdAt: createdAt,
    );
  }

  @override
  Future<Player> logIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final needle = emailOrUsername.trim().toLowerCase();
    final email = needle.contains('@')
        ? needle
        : await _gateway.lookupEmailByUsername(needle);
    if (email == null) {
      throw const AuthInvalidCredentialsException();
    }
    final String playerId;
    try {
      playerId = await _gateway.signInWithEmailPassword(
        email: email,
        password: password,
      );
    } on GatewayInvalidCredentialsException {
      throw const AuthInvalidCredentialsException();
    }
    final row = await _gateway.fetchPlayerRow(playerId);
    if (row == null) {
      throw const AuthUnknownException('profile_missing_after_login');
    }
    return Player.fromJson(row);
  }

  @override
  Future<void> signOut() => _gateway.signOut();

  @override
  Future<Player?> getCurrentPlayer() async {
    final id = _gateway.currentAuthUserId();
    if (id == null) return null;
    final row = await _gateway.fetchPlayerRow(id);
    if (row == null) return null;
    return Player.fromJson(row);
  }

  @override
  Future<void> deleteAccount() async {
    final id = _gateway.currentAuthUserId();
    if (id == null) throw const AuthNotLoggedInException();
    await _gateway.deleteCurrentAccount();
  }

  @override
  Stream<Player?> watchCurrentPlayer() {
    late StreamController<Player?> controller;
    StreamSubscription<String?>? sub;

    Future<void> emitFor(String? id) async {
      if (controller.isClosed) return;
      if (id == null) {
        controller.add(null);
        return;
      }
      final row = await _gateway.fetchPlayerRow(id);
      if (controller.isClosed) return;
      controller.add(row == null ? null : Player.fromJson(row));
    }

    controller = StreamController<Player?>(
      onListen: () {
        // Emit the current state first, then subscribe to changes.
        () async {
          final current = await getCurrentPlayer();
          if (controller.isClosed) return;
          controller.add(current);
        }();
        sub = _gateway.authUserIdChanges().listen(emitFor);
      },
      onCancel: () async {
        await sub?.cancel();
        sub = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<void> adoptUpdatedProfile(Player player) async {
    // Session row is read from Postgres on each [getCurrentPlayer]; auth
    // user id stream does not fire on username-only writes.
  }
}
