// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileViewDataHash() => r'211a677a947dd36d6b0728d5525ac99877415f46';

/// Profile header fields for [ProfileScreen] (Phase 2B.7).
///
/// Stats come from [PlayerRepository.fetchPerformanceStats]. When the
/// ranked-stats RPC is missing or errors (B-GAP-2), falls back to zeros.
///
/// Copied from [profileViewData].
@ProviderFor(profileViewData)
final profileViewDataProvider =
    AutoDisposeFutureProvider<ProfileViewData>.internal(
      profileViewData,
      name: r'profileViewDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$profileViewDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileViewDataRef = AutoDisposeFutureProviderRef<ProfileViewData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
