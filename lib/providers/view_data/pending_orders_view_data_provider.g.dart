// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_orders_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingOrdersViewDataHash() =>
    r'1453c232d3ea68654d423a462ed8ef72ff92d9a1';

/// Cross-game pending resting / in-flight orders plus games where the player
/// may create orders (`trading_started`).
///
/// Copied from [pendingOrdersViewData].
@ProviderFor(pendingOrdersViewData)
final pendingOrdersViewDataProvider =
    AutoDisposeFutureProvider<PendingOrdersScreenData>.internal(
      pendingOrdersViewData,
      name: r'pendingOrdersViewDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingOrdersViewDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingOrdersViewDataRef =
    AutoDisposeFutureProviderRef<PendingOrdersScreenData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
