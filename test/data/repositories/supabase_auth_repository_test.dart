import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/repositories/auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/supabase_auth_repository.dart';
import 'package:uncertain_envelopes_2/services/supabase_auth_gateway.dart';

/// Tests target the repository's business logic (exception translation,
/// username-vs-email routing, profile fetch sequencing). The Supabase
/// gateway is a thin seam and is replaced here with a deterministic fake.
void main() {
  group('SupabaseAuthRepository', () {
    late _FakeGateway gateway;
    late SupabaseAuthRepository repo;

    setUp(() {
      gateway = _FakeGateway();
      repo = SupabaseAuthRepository(
        gateway: gateway,
        now: () => DateTime.utc(2026, 1, 1, 12),
      );
    });

    test('signUp creates auth user and player row, returns Player', () async {
      gateway.nextCreateAuthUserId = 'auth-1';
      final p = await repo.signUp(
        email: 'Alice@Example.com',
        password: 'pw',
        username: 'Alice',
      );
      expect(p.playerId, 'auth-1');
      expect(p.email, 'alice@example.com');
      expect(p.username, 'alice');
      expect(p.createdAt, DateTime.utc(2026, 1, 1, 12));
      expect(gateway.createdAuthUsers, [
        _Creds(email: 'alice@example.com', password: 'pw'),
      ]);
      expect(gateway.insertedRows.single['player_id'], 'auth-1');
      expect(gateway.insertedRows.single['email'], 'alice@example.com');
      expect(gateway.insertedRows.single['username'], 'alice');
    });

    test('signUp translates email-in-use error', () async {
      gateway.throwOnCreateAuthUser = const GatewayEmailInUseException();
      expect(
        () => repo.signUp(email: 'a@x.com', password: 'pw', username: 'a'),
        throwsA(isA<AuthEmailAlreadyInUseException>()),
      );
    });

    test('signUp translates username-in-use error', () async {
      gateway.nextCreateAuthUserId = 'auth-2';
      gateway.throwOnInsertPlayerRow =
          const GatewayUsernameInUseException();
      expect(
        () => repo.signUp(email: 'a@x.com', password: 'pw', username: 'a'),
        throwsA(isA<AuthUsernameAlreadyInUseException>()),
      );
    });

    test('logIn with email skips username lookup', () async {
      gateway.nextSignInUserId = 'auth-3';
      gateway.playerRows['auth-3'] = _sampleRow('auth-3', 'a@x.com', 'alice');
      final p = await repo.logIn(
        emailOrUsername: 'a@x.com',
        password: 'pw',
      );
      expect(p.playerId, 'auth-3');
      expect(gateway.usernameLookups, isEmpty);
      expect(gateway.signInAttempts,
          [_Creds(email: 'a@x.com', password: 'pw')]);
    });

    test('logIn with username resolves email then signs in', () async {
      gateway.usernameToEmail['alice'] = 'a@x.com';
      gateway.nextSignInUserId = 'auth-3';
      gateway.playerRows['auth-3'] = _sampleRow('auth-3', 'a@x.com', 'alice');
      final p = await repo.logIn(
        emailOrUsername: 'Alice',
        password: 'pw',
      );
      expect(p.username, 'alice');
      expect(gateway.usernameLookups, ['alice']);
      expect(gateway.signInAttempts.single.email, 'a@x.com');
    });

    test('logIn with unknown username throws invalid credentials', () async {
      expect(
        () => repo.logIn(
          emailOrUsername: 'nobody',
          password: 'pw',
        ),
        throwsA(isA<AuthInvalidCredentialsException>()),
      );
    });

    test('logIn translates invalid credentials from gateway', () async {
      gateway.throwOnSignIn = const GatewayInvalidCredentialsException();
      expect(
        () => repo.logIn(emailOrUsername: 'a@x.com', password: 'pw'),
        throwsA(isA<AuthInvalidCredentialsException>()),
      );
    });

    test('logIn with missing profile row throws unknown', () async {
      gateway.nextSignInUserId = 'auth-7';
      // Deliberately do not populate playerRows['auth-7'].
      expect(
        () => repo.logIn(emailOrUsername: 'a@x.com', password: 'pw'),
        throwsA(isA<AuthUnknownException>()),
      );
    });

    test('signOut delegates to gateway', () async {
      await repo.signOut();
      expect(gateway.signOutCalls, 1);
    });

    test('getCurrentPlayer returns null when not logged in', () async {
      expect(await repo.getCurrentPlayer(), isNull);
    });

    test('getCurrentPlayer returns Player when logged in', () async {
      gateway.currentUserId = 'auth-9';
      gateway.playerRows['auth-9'] = _sampleRow('auth-9', 'a@x.com', 'alice');
      final p = await repo.getCurrentPlayer();
      expect(p?.playerId, 'auth-9');
      expect(p?.username, 'alice');
    });

    test('getCurrentPlayer returns null when auth exists but row missing',
        () async {
      // This is the corrupt-state path: Supabase Auth has a user but the
      // players row was never inserted. UI should treat this as logged out.
      gateway.currentUserId = 'auth-10';
      expect(await repo.getCurrentPlayer(), isNull);
    });

    test('deleteAccount requires active session', () async {
      expect(
        () => repo.deleteAccount(),
        throwsA(isA<AuthNotLoggedInException>()),
      );
    });

    test('deleteAccount calls gateway when session exists', () async {
      gateway.currentUserId = 'auth-11';
      await repo.deleteAccount();
      expect(gateway.deleteCalls, 1);
    });

    test(
      'watchCurrentPlayer emits current value then auth state changes',
      () async {
        gateway.currentUserId = 'auth-1';
        gateway.playerRows['auth-1'] =
            _sampleRow('auth-1', 'a@x.com', 'alice');
        gateway.playerRows['auth-2'] =
            _sampleRow('auth-2', 'b@x.com', 'bob');

        final events = <String?>[];
        final sub = repo.watchCurrentPlayer().listen(
              (p) => events.add(p?.username),
            );

        await Future<void>.delayed(Duration.zero);
        expect(events, ['alice']);

        gateway.emitAuth('auth-2');
        await Future<void>.delayed(Duration.zero);
        expect(events, ['alice', 'bob']);

        gateway.emitAuth(null);
        await Future<void>.delayed(Duration.zero);
        expect(events, ['alice', 'bob', null]);

        await sub.cancel();
      },
    );
  });
}

Map<String, dynamic> _sampleRow(String id, String email, String username) => {
      'player_id': id,
      'email': email,
      'username': username,
      'created_at': '2026-01-01T00:00:00.000Z',
    };

class _Creds {
  _Creds({required this.email, required this.password});
  final String email;
  final String password;
  @override
  bool operator ==(Object other) =>
      other is _Creds && other.email == email && other.password == password;
  @override
  int get hashCode => Object.hash(email, password);
  @override
  String toString() => 'Creds($email, $password)';
}

class _FakeGateway implements SupabaseAuthGateway {
  String? nextCreateAuthUserId;
  GatewayException? throwOnCreateAuthUser;
  String? nextSignInUserId;
  GatewayException? throwOnSignIn;
  GatewayException? throwOnInsertPlayerRow;
  String? currentUserId;

  final List<_Creds> createdAuthUsers = [];
  final List<Map<String, dynamic>> insertedRows = [];
  final List<_Creds> signInAttempts = [];
  final List<String> usernameLookups = [];
  int signOutCalls = 0;
  int deleteCalls = 0;
  final Map<String, Map<String, dynamic>> playerRows = {};
  final Map<String, String> usernameToEmail = {};
  final StreamController<String?> _authStream =
      StreamController<String?>.broadcast();

  void emitAuth(String? id) {
    currentUserId = id;
    _authStream.add(id);
  }

  @override
  Future<String> createAuthUser({
    required String email,
    required String password,
  }) async {
    if (throwOnCreateAuthUser != null) throw throwOnCreateAuthUser!;
    createdAuthUsers.add(_Creds(email: email, password: password));
    final id = nextCreateAuthUserId ?? 'generated-${createdAuthUsers.length}';
    currentUserId = id;
    return id;
  }

  @override
  Future<String> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (throwOnSignIn != null) throw throwOnSignIn!;
    signInAttempts.add(_Creds(email: email, password: password));
    final id = nextSignInUserId ?? 'signed-in';
    currentUserId = id;
    return id;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    currentUserId = null;
  }

  @override
  String? currentAuthUserId() => currentUserId;

  @override
  Stream<String?> authUserIdChanges() => _authStream.stream;

  @override
  Future<void> insertPlayerRow({
    required String playerId,
    required String email,
    required String username,
    required DateTime createdAt,
  }) async {
    if (throwOnInsertPlayerRow != null) throw throwOnInsertPlayerRow!;
    insertedRows.add({
      'player_id': playerId,
      'email': email,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    });
    playerRows[playerId] = {
      'player_id': playerId,
      'email': email,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchPlayerRow(String playerId) async {
    return playerRows[playerId];
  }

  @override
  Future<String?> lookupEmailByUsername(String username) async {
    usernameLookups.add(username);
    return usernameToEmail[username];
  }

  @override
  Future<void> deleteCurrentAccount() async {
    deleteCalls++;
    final id = currentUserId;
    if (id != null) {
      playerRows.remove(id);
    }
    currentUserId = null;
  }
}
