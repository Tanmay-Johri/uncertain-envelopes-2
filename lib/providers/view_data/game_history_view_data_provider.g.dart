// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_history_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameHistoryViewDataHash() =>
    r'7b910f728a3c6f773735230130e294db9a0db45a';

/// Completed games for [GameHistoryScreen], derived from joined games in
/// terminal states (Phase 2B.9 — no dedicated SQL yet).
///
/// Copied from [gameHistoryViewData].
@ProviderFor(gameHistoryViewData)
final gameHistoryViewDataProvider =
    AutoDisposeFutureProvider<List<GameHistoryEntry>>.internal(
      gameHistoryViewData,
      name: r'gameHistoryViewDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$gameHistoryViewDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GameHistoryViewDataRef =
    AutoDisposeFutureProviderRef<List<GameHistoryEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
