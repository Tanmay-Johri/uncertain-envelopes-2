// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clockHash() => r'3f65ad34ac6fcd532de9004042bdf2ed2bd85b13';

/// Wall clock. Overridden by tests to make time deterministic.
///
/// Copied from [clock].
@ProviderFor(clock)
final clockProvider = Provider<DateTime Function()>.internal(
  clock,
  name: r'clockProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clockHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClockRef = ProviderRef<DateTime Function()>;
String _$timerTickStreamHash() => r'61f985795af286e532c08f0891d8b2a7ee2be2e9';

/// One-second ticker used to drive the countdown timer provider. Each
/// emitted value IS the wall-clock instant at the moment of the tick, so
/// the timer provider only needs to compute `endTime - tick`.
///
/// Tests should override this with a `StreamController.broadcast()` and
/// push custom [DateTime] values. Without an override, a real periodic
/// timer is used.
///
/// Copied from [timerTickStream].
@ProviderFor(timerTickStream)
final timerTickStreamProvider = StreamProvider<DateTime>.internal(
  timerTickStream,
  name: r'timerTickStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timerTickStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TimerTickStreamRef = StreamProviderRef<DateTime>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
