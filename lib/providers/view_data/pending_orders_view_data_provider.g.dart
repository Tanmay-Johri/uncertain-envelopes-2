// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_orders_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingOrdersViewDataHash() =>
    r'374406c7e3fa6d9ed63029875c1465aae2098d8f';

/// Cross-game pending resting / in-flight orders plus games where the player
/// may create orders (`trading_started`).
///
/// [silentRefresh] updates rows **without** going through [AsyncLoading], so
/// periodic refreshes do not flash the loading skeleton.
///
/// Copied from [PendingOrdersViewData].
@ProviderFor(PendingOrdersViewData)
final pendingOrdersViewDataProvider =
    AsyncNotifierProvider<
      PendingOrdersViewData,
      PendingOrdersScreenData
    >.internal(
      PendingOrdersViewData.new,
      name: r'pendingOrdersViewDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingOrdersViewDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PendingOrdersViewData = AsyncNotifier<PendingOrdersScreenData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
