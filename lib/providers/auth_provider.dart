import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/player.dart';
import '../data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

/// Injection point for the [AuthRepository] implementation. `main()` and
/// tests must override this provider — there is no sensible default
/// because the concrete impl needs a live `SupabaseClient`.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden (in main() with '
    'SupabaseAuthRepository, or in tests with InMemoryAuthRepository).',
  );
}

/// Top-level auth controller. The exposed state is the currently logged-in
/// [Player] (or null when logged out) wrapped in [AsyncValue]. Actions
/// return when the state has settled to either data or error so callers
/// can `await` and branch on `state.hasError`.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  StreamSubscription<Player?>? _sub;

  @override
  Future<Player?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    _sub?.cancel();
    _sub = repo.watchCurrentPlayer().listen(
      (player) => state = AsyncValue.data(player),
      onError: (Object e, StackTrace st) =>
          state = AsyncValue.error(e, st),
    );
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });
    // Return the synchronous "best known" initial value so the first
    // frame isn't flagged as loading if the session is already resolved.
    return repo.getCurrentPlayer();
  }

  bool get isLoggedIn => state.valueOrNull != null;

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, username: username),
    );
  }

  Future<void> logIn({
    required String emailOrUsername,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).logIn(
            emailOrUsername: emailOrUsername,
            password: password,
          ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return null;
    });
  }

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).deleteAccount();
      return null;
    });
  }
}
