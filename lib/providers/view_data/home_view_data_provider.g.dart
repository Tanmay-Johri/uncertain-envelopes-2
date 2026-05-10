// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeViewDataHash() => r'a32a7c4e6be9c7fe2db01e952c06b1e8c1cfca82';

/// Joined + public discovery rows for the signed-in player (Phase 2B.2).
///
/// [silentRefresh] updates the list **without** going through [AsyncLoading],
/// so periodic / resume refreshes do not flash the loading skeleton.
///
/// Copied from [HomeViewData].
@ProviderFor(HomeViewData)
final homeViewDataProvider =
    AsyncNotifierProvider<HomeViewData, List<MockHomeGame>>.internal(
      HomeViewData.new,
      name: r'homeViewDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$homeViewDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HomeViewData = AsyncNotifier<List<MockHomeGame>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
