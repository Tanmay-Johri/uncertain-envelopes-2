import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/player.dart';
import 'auth_repository.dart';

/// Deterministic in-memory [AuthRepository] used by tests. Intentionally
/// behaves like the real backend for happy-path flows and the key error
/// cases (duplicate email / username, unknown login, delete without
/// session).
///
/// Stream semantics: [watchCurrentPlayer] emits the current value on
/// subscription and on every state change.
class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, _PlayerRecord> _byEmail = {};
  Player? _current;
  final StreamController<Player?> _controller =
      StreamController<Player?>.broadcast();

  @override
  Future<Player> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final e = email.trim().toLowerCase();
    final u = username.trim().toLowerCase();
    if (_byEmail.containsKey(e)) {
      throw const AuthEmailAlreadyInUseException();
    }
    if (_byEmail.values.any((r) => r.player.username == u)) {
      throw const AuthUsernameAlreadyInUseException();
    }
    final player = Player(
      playerId: const Uuid().v4(),
      username: u,
      createdAt: _now(),
      email: e,
    );
    _byEmail[e] = _PlayerRecord(player: player, password: password);
    _setCurrent(player);
    return player;
  }

  @override
  Future<Player> logIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final needle = emailOrUsername.trim().toLowerCase();
    final record = needle.contains('@')
        ? _byEmail[needle]
        : _byEmail.values
            .cast<_PlayerRecord?>()
            .firstWhere(
              (r) => r!.player.username == needle,
              orElse: () => null,
            );
    if (record == null || record.password != password) {
      throw const AuthInvalidCredentialsException();
    }
    _setCurrent(record.player);
    return record.player;
  }

  @override
  Future<void> signOut() async {
    _setCurrent(null);
  }

  @override
  Future<Player?> getCurrentPlayer() async => _current;

  @override
  Future<void> deleteAccount() async {
    final c = _current;
    if (c == null) throw const AuthNotLoggedInException();
    _byEmail.remove(c.email);
    _setCurrent(null);
  }

  @override
  Stream<Player?> watchCurrentPlayer() {
    // Build a per-subscription stream that replays the current value on
    // subscribe and then forwards every state change. An `async*` body
    // used to be here but deferred its `yield* _controller.stream`
    // subscription by one microtask, which could miss an event fired
    // immediately after a new subscriber attached.
    late StreamController<Player?> out;
    StreamSubscription<Player?>? inner;
    out = StreamController<Player?>(
      onListen: () {
        out.add(_current);
        inner = _controller.stream.listen(out.add);
      },
      onCancel: () async {
        await inner?.cancel();
      },
    );
    return out.stream;
  }

  void _setCurrent(Player? p) {
    _current = p;
    _controller.add(p);
  }

  /// Test-only shutdown hook.
  Future<void> dispose() => _controller.close();
}

class _PlayerRecord {
  _PlayerRecord({required this.player, required this.password});
  final Player player;
  final String password;
}
