// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'results_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$resultsViewDataHash() => r'8c811e7ffad4eb5c53fcc58664a79fc7dcf6363f';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Final results leaderboard + envelope state for [gameId].
///
/// Copied from [resultsViewData].
@ProviderFor(resultsViewData)
const resultsViewDataProvider = ResultsViewDataFamily();

/// Final results leaderboard + envelope state for [gameId].
///
/// Copied from [resultsViewData].
class ResultsViewDataFamily extends Family<AsyncValue<GameResultsViewData>> {
  /// Final results leaderboard + envelope state for [gameId].
  ///
  /// Copied from [resultsViewData].
  const ResultsViewDataFamily();

  /// Final results leaderboard + envelope state for [gameId].
  ///
  /// Copied from [resultsViewData].
  ResultsViewDataProvider call(String gameId) {
    return ResultsViewDataProvider(gameId);
  }

  @override
  ResultsViewDataProvider getProviderOverride(
    covariant ResultsViewDataProvider provider,
  ) {
    return call(provider.gameId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'resultsViewDataProvider';
}

/// Final results leaderboard + envelope state for [gameId].
///
/// Copied from [resultsViewData].
class ResultsViewDataProvider
    extends AutoDisposeFutureProvider<GameResultsViewData> {
  /// Final results leaderboard + envelope state for [gameId].
  ///
  /// Copied from [resultsViewData].
  ResultsViewDataProvider(String gameId)
    : this._internal(
        (ref) => resultsViewData(ref as ResultsViewDataRef, gameId),
        from: resultsViewDataProvider,
        name: r'resultsViewDataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$resultsViewDataHash,
        dependencies: ResultsViewDataFamily._dependencies,
        allTransitiveDependencies:
            ResultsViewDataFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  ResultsViewDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.gameId,
  }) : super.internal();

  final String gameId;

  @override
  Override overrideWith(
    FutureOr<GameResultsViewData> Function(ResultsViewDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResultsViewDataProvider._internal(
        (ref) => create(ref as ResultsViewDataRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        gameId: gameId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GameResultsViewData> createElement() {
    return _ResultsViewDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResultsViewDataProvider && other.gameId == gameId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, gameId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ResultsViewDataRef on AutoDisposeFutureProviderRef<GameResultsViewData> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _ResultsViewDataProviderElement
    extends AutoDisposeFutureProviderElement<GameResultsViewData>
    with ResultsViewDataRef {
  _ResultsViewDataProviderElement(super.provider);

  @override
  String get gameId => (origin as ResultsViewDataProvider).gameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
