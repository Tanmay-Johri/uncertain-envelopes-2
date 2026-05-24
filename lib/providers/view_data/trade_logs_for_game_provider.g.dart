// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_logs_for_game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tradeLogsForGameHash() => r'a1d2475764437e63f93f8b849b7e7176129a532c';

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

/// Executed trades for [gameId], for the transaction log sheet on any screen.
///
/// Copied from [tradeLogsForGame].
@ProviderFor(tradeLogsForGame)
const tradeLogsForGameProvider = TradeLogsForGameFamily();

/// Executed trades for [gameId], for the transaction log sheet on any screen.
///
/// Copied from [tradeLogsForGame].
class TradeLogsForGameFamily extends Family<AsyncValue<List<TradeLogEntry>>> {
  /// Executed trades for [gameId], for the transaction log sheet on any screen.
  ///
  /// Copied from [tradeLogsForGame].
  const TradeLogsForGameFamily();

  /// Executed trades for [gameId], for the transaction log sheet on any screen.
  ///
  /// Copied from [tradeLogsForGame].
  TradeLogsForGameProvider call(String gameId) {
    return TradeLogsForGameProvider(gameId);
  }

  @override
  TradeLogsForGameProvider getProviderOverride(
    covariant TradeLogsForGameProvider provider,
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
  String? get name => r'tradeLogsForGameProvider';
}

/// Executed trades for [gameId], for the transaction log sheet on any screen.
///
/// Copied from [tradeLogsForGame].
class TradeLogsForGameProvider
    extends AutoDisposeFutureProvider<List<TradeLogEntry>> {
  /// Executed trades for [gameId], for the transaction log sheet on any screen.
  ///
  /// Copied from [tradeLogsForGame].
  TradeLogsForGameProvider(String gameId)
    : this._internal(
        (ref) => tradeLogsForGame(ref as TradeLogsForGameRef, gameId),
        from: tradeLogsForGameProvider,
        name: r'tradeLogsForGameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$tradeLogsForGameHash,
        dependencies: TradeLogsForGameFamily._dependencies,
        allTransitiveDependencies:
            TradeLogsForGameFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  TradeLogsForGameProvider._internal(
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
    FutureOr<List<TradeLogEntry>> Function(TradeLogsForGameRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TradeLogsForGameProvider._internal(
        (ref) => create(ref as TradeLogsForGameRef),
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
  AutoDisposeFutureProviderElement<List<TradeLogEntry>> createElement() {
    return _TradeLogsForGameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TradeLogsForGameProvider && other.gameId == gameId;
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
mixin TradeLogsForGameRef on AutoDisposeFutureProviderRef<List<TradeLogEntry>> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _TradeLogsForGameProviderElement
    extends AutoDisposeFutureProviderElement<List<TradeLogEntry>>
    with TradeLogsForGameRef {
  _TradeLogsForGameProviderElement(super.provider);

  @override
  String get gameId => (origin as TradeLogsForGameProvider).gameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
