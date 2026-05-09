// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appRouterInitialLocationHash() =>
    r'9f15ad3f90e3c15b2938cccc5dc2e7781f3e6c6c';

/// Initial location for [appRouterProvider]. Override in tests to deep-link.
///
/// Copied from [appRouterInitialLocation].
@ProviderFor(appRouterInitialLocation)
final appRouterInitialLocationProvider = Provider<String>.internal(
  appRouterInitialLocation,
  name: r'appRouterInitialLocationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appRouterInitialLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppRouterInitialLocationRef = ProviderRef<String>;
String _$appRouterHash() => r'ed5dfff9b4e1cc2acc5e0049805fa2ea5f29ce07';

/// Production [GoRouter]: auth redirect + refresh on session changes (2B.1).
///
/// Copied from [appRouter].
@ProviderFor(appRouter)
final appRouterProvider = Provider<GoRouter>.internal(
  appRouter,
  name: r'appRouterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appRouterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppRouterRef = ProviderRef<GoRouter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
