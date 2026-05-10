// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_orders_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingOrdersViewDataHash() =>
    r'5bbd7e71a364ad3b314d50fc2d34502ef5c56069';

/// Cross-game pending resting / in-flight orders for [PendingOrdersScreen].
///
/// Copied from [pendingOrdersViewData].
@ProviderFor(pendingOrdersViewData)
final pendingOrdersViewDataProvider =
    AutoDisposeFutureProvider<List<PendingOrderListItem>>.internal(
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
    AutoDisposeFutureProviderRef<List<PendingOrderListItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
