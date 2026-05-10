import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/player.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/in_memory_auth_repository.dart';
import '../data/repositories/supabase_auth_repository.dart';
import '../services/supabase_auth_gateway.dart';
import '_environment.dart';

part 'auth_provider.g.dart';

/// Global [AuthRepository]. Defaults to [InMemoryAuthRepository]; set
/// `USE_REAL_BACKEND=true` at compile time for [SupabaseAuthRepository].
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  if (useRealBackend) {
    return SupabaseAuthRepository(
      gateway: RealSupabaseAuthGateway(Supabase.instance.client),
    );
  }
  return InMemoryAuthRepository();
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

  /// Call after [PlayerRepository.updateUsername] succeeds for the signed-in
  /// user so in-memory auth cache matches Postgres.
  Future<void> adoptUpdatedProfile(Player player) async {
    await ref.read(authRepositoryProvider).adoptUpdatedProfile(player);
    state = AsyncValue.data(player);
  }
}
