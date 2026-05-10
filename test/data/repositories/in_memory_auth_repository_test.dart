import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/repositories/auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';

/// The in-memory repository is the fake used by the rest of the app's
/// tests. These cases pin the happy path, the common error classes, and
/// the contract around `watchCurrentPlayer`.
void main() {
  group('InMemoryAuthRepository', () {
    late InMemoryAuthRepository repo;

    setUp(() {
      repo = InMemoryAuthRepository(
        now: () => DateTime.utc(2026, 1, 1, 12),
      );
    });

    tearDown(() async {
      await repo.dispose();
    });

    test('signUp stores player and sets current', () async {
      final p = await repo.signUp(
        email: 'Alice@example.com',
        password: 'hunter2',
        username: 'Alice',
      );
      expect(p.email, 'alice@example.com');
      expect(p.username, 'alice');
      expect(p.createdAt, DateTime.utc(2026, 1, 1, 12));
      expect(await repo.getCurrentPlayer(), p);
    });

    test('signUp rejects duplicate email case-insensitively', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      expect(
        () => repo.signUp(
          email: 'A@X.COM',
          password: 'pw2',
          username: 'bob',
        ),
        throwsA(isA<AuthEmailAlreadyInUseException>()),
      );
    });

    test('signUp rejects duplicate username case-insensitively', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      expect(
        () => repo.signUp(
          email: 'b@x.com',
          password: 'pw',
          username: 'ALICE',
        ),
        throwsA(isA<AuthUsernameAlreadyInUseException>()),
      );
    });

    test('logIn with email succeeds and sets current', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      await repo.signOut();
      final p =
          await repo.logIn(emailOrUsername: 'a@x.com', password: 'pw');
      expect(p.email, 'a@x.com');
      expect(await repo.getCurrentPlayer(), isNotNull);
    });

    test('logIn with username resolves to email', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      await repo.signOut();
      final p =
          await repo.logIn(emailOrUsername: 'Alice', password: 'pw');
      expect(p.email, 'a@x.com');
    });

    test('logIn with wrong password throws invalid credentials', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      await repo.signOut();
      expect(
        () => repo.logIn(emailOrUsername: 'a@x.com', password: 'nope'),
        throwsA(isA<AuthInvalidCredentialsException>()),
      );
    });

    test('logIn with unknown user throws invalid credentials', () async {
      expect(
        () => repo.logIn(emailOrUsername: 'nobody@x.com', password: 'pw'),
        throwsA(isA<AuthInvalidCredentialsException>()),
      );
    });

    test('signOut clears current player', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      await repo.signOut();
      expect(await repo.getCurrentPlayer(), isNull);
    });

    test('signOut when already logged out is a no-op', () async {
      await repo.signOut();
      expect(await repo.getCurrentPlayer(), isNull);
    });

    test('deleteAccount removes record and clears session', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      await repo.deleteAccount();
      expect(await repo.getCurrentPlayer(), isNull);
      // Can sign up again with the same email after deletion.
      final p2 = await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      expect(p2.email, 'a@x.com');
    });

    test('deleteAccount without session throws', () async {
      expect(
        () => repo.deleteAccount(),
        throwsA(isA<AuthNotLoggedInException>()),
      );
    });

    test('watchCurrentPlayer emits current value on subscribe', () async {
      await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      await expectLater(repo.watchCurrentPlayer().take(1), emits(isNotNull));
    });

    test(
      'watchCurrentPlayer emits null after signOut',
      () async {
        await repo.signUp(
          email: 'a@x.com',
          password: 'pw',
          username: 'alice',
        );
        final events = <Object?>[];
        final sub = repo.watchCurrentPlayer().listen(events.add);
        // The current value + any future state changes.
        await Future<void>.delayed(Duration.zero);
        expect(events.length, 1);
        expect(events.single, isNotNull);
        await repo.signOut();
        await Future<void>.delayed(Duration.zero);
        expect(events.last, isNull);
        await sub.cancel();
      },
    );

    test('rapid signUp/signOut/logIn does not leak state', () async {
      for (var i = 0; i < 5; i++) {
        await repo.signUp(
          email: 'user$i@x.com',
          password: 'pw',
          username: 'user$i',
        );
        await repo.signOut();
      }
      final p =
          await repo.logIn(emailOrUsername: 'user3@x.com', password: 'pw');
      expect(p.username, 'user3');
      expect(await repo.getCurrentPlayer(), p);
    });

    test('adoptUpdatedProfile syncs session + email index for username edits',
        () async {
      final p = await repo.signUp(
        email: 'a@x.com',
        password: 'pw',
        username: 'alice',
      );
      final updated = p.copyWith(username: 'alicia');
      await repo.adoptUpdatedProfile(updated);
      expect((await repo.getCurrentPlayer())!.username, 'alicia');
      final p2 =
          await repo.logIn(emailOrUsername: 'a@x.com', password: 'pw');
      expect(p2.username, 'alicia');
    });
  });
}
