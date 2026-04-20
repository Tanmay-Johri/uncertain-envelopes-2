// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'0e668786fe1c0aebd45ec4e26e247a421b00eab8';

/// Injection point for the [AuthRepository] implementation. `main()` and
/// tests must override this provider — there is no sensible default
/// because the concrete impl needs a live `SupabaseClient`.
///
/// Copied from [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = Provider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = ProviderRef<AuthRepository>;
String _$authControllerHash() => r'f1de357d2833c5990e982cce11402b8818dcf8cb';

/// Top-level auth controller. The exposed state is the currently logged-in
/// [Player] (or null when logged out) wrapped in [AsyncValue]. Actions
/// return when the state has settled to either data or error so callers
/// can `await` and branch on `state.hasError`.
///
/// Copied from [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AsyncNotifierProvider<AuthController, Player?>.internal(
      AuthController.new,
      name: r'authControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthController = AsyncNotifier<Player?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
