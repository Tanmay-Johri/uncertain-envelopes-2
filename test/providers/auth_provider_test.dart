import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/data/models/player.dart';
import 'package:uncertain_envelopes_2/data/repositories/auth_repository.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';

/// End-to-end behaviour of [authControllerProvider] against a real
/// [InMemoryAuthRepository]. This is the fake every other provider test
/// will reuse, so its lifecycle must be rock-solid.
void main() {
  late InMemoryAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryAuthRepository(
      now: () => DateTime.utc(2026, 1, 1, 12),
    );
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await repo.dispose();
  });

  test('initial state is logged out (null player, no error)', () async {
    final value = await container.read(authControllerProvider.future);
    expect(value, isNull);
    expect(container.read(authControllerProvider).hasError, false);
  });

  test('signUp happy path transitions through loading -> data(player)',
      () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    final states = <AsyncValue<Player?>>[];
    final removeListener = container.listen<AsyncValue<Player?>>(
      authControllerProvider,
      (_, next) => states.add(next),
    ).close;

    await notifier.signUp(
      email: 'a@x.com',
      password: 'pw',
      username: 'alice',
    );

    expect(
      states.any((s) => s.isLoading),
      true,
      reason: 'expected at least one loading state during signUp',
    );
    final last = container.read(authControllerProvider);
    expect(last.hasError, false);
    expect(last.valueOrNull?.username, 'alice');
    expect(notifier.isLoggedIn, true);
    removeListener();
  });

  test('signUp with duplicate email ends in AsyncError', () async {
    await repo.signUp(
      email: 'a@x.com',
      password: 'pw',
      username: 'alice',
    );
    await repo.signOut();

    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.signUp(
      email: 'a@x.com',
      password: 'pw',
      username: 'other',
    );

    final s = container.read(authControllerProvider);
    expect(s.hasError, true);
    expect(s.error, isA<AuthEmailAlreadyInUseException>());
  });

  test('logIn happy path and signOut returns to null', () async {
    await repo.signUp(
      email: 'a@x.com',
      password: 'pw',
      username: 'alice',
    );
    await repo.signOut();

    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.logIn(
      emailOrUsername: 'alice',
      password: 'pw',
    );
    expect(
      container.read(authControllerProvider).valueOrNull?.username,
      'alice',
    );

    await notifier.signOut();
    expect(container.read(authControllerProvider).valueOrNull, isNull);
    expect(notifier.isLoggedIn, false);
  });

  test('logIn with wrong password produces AsyncError', () async {
    await repo.signUp(
      email: 'a@x.com',
      password: 'pw',
      username: 'alice',
    );
    await repo.signOut();

    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.logIn(
      emailOrUsername: 'a@x.com',
      password: 'WRONG',
    );
    final s = container.read(authControllerProvider);
    expect(s.hasError, true);
    expect(s.error, isA<AuthInvalidCredentialsException>());
  });

  test(
    'repository auth state changes propagate into the controller',
    () async {
      await container.read(authControllerProvider.future);
      // External sign-up bypasses the controller — simulates, for example,
      // a deep link or another tab driving the session.
      await repo.signUp(
        email: 'b@x.com',
        password: 'pw',
        username: 'bob',
      );
      await Future<void>.delayed(Duration.zero);
      final current = container.read(authControllerProvider).valueOrNull;
      expect(current?.username, 'bob');
    },
  );

  test('deleteAccount clears session and resets state', () async {
    await repo.signUp(
      email: 'a@x.com',
      password: 'pw',
      username: 'alice',
    );
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);
    await notifier.deleteAccount();
    expect(container.read(authControllerProvider).valueOrNull, isNull);
  });

  test('deleteAccount without session puts the controller into error state',
      () async {
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);
    await notifier.deleteAccount();
    final s = container.read(authControllerProvider);
    expect(s.hasError, true);
    expect(s.error, isA<AuthNotLoggedInException>());
  });

  test('rapid sign-out repeats are a no-op at the controller level',
      () async {
    await repo.signUp(
      email: 'a@x.com',
      password: 'pw',
      username: 'alice',
    );
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);
    await notifier.signOut();
    await notifier.signOut();
    await notifier.signOut();
    expect(container.read(authControllerProvider).valueOrNull, isNull);
    expect(container.read(authControllerProvider).hasError, false);
  });

  test('unoverridden authRepositoryProvider throws UnimplementedError', () {
    final bareContainer = ProviderContainer();
    addTearDown(bareContainer.dispose);
    expect(
      () => bareContainer.read(authRepositoryProvider),
      throwsA(isA<UnimplementedError>()),
    );
  });
}
