// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tradingViewDataHash() => r'9f4161e08bd323c8b908eaa966b1b7d4c11c1ad4';

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

/// Trading dashboard snapshot for [gameId] (Phase 2B.5).
///
/// Does **not** subscribe to the timer tick for its AsyncNotifier rebuild.
/// [GameTradingViewData.chartSessionElapsed] is therefore a snapshot when the
/// payload was built. The live trading route passes
/// [GameTradingScreen.liveChartSessionElapsed] from [chartSessionElapsedProvider]
/// so the price chart advances with wall-clock session time without refetching
/// this snapshot every tick. For timed games, [GameTradingViewData.tradingDeadlineUtc]
/// carries `games.end_time_decided`; [CountdownTimer] recomputes each tick from that
/// instant so all devices stay aligned with the server field.
///
/// Copied from [tradingViewData].
@ProviderFor(tradingViewData)
const tradingViewDataProvider = TradingViewDataFamily();

/// Trading dashboard snapshot for [gameId] (Phase 2B.5).
///
/// Does **not** subscribe to the timer tick for its AsyncNotifier rebuild.
/// [GameTradingViewData.chartSessionElapsed] is therefore a snapshot when the
/// payload was built. The live trading route passes
/// [GameTradingScreen.liveChartSessionElapsed] from [chartSessionElapsedProvider]
/// so the price chart advances with wall-clock session time without refetching
/// this snapshot every tick. For timed games, [GameTradingViewData.tradingDeadlineUtc]
/// carries `games.end_time_decided`; [CountdownTimer] recomputes each tick from that
/// instant so all devices stay aligned with the server field.
///
/// Copied from [tradingViewData].
class TradingViewDataFamily extends Family<AsyncValue<GameTradingViewData>> {
  /// Trading dashboard snapshot for [gameId] (Phase 2B.5).
  ///
  /// Does **not** subscribe to the timer tick for its AsyncNotifier rebuild.
  /// [GameTradingViewData.chartSessionElapsed] is therefore a snapshot when the
  /// payload was built. The live trading route passes
  /// [GameTradingScreen.liveChartSessionElapsed] from [chartSessionElapsedProvider]
  /// so the price chart advances with wall-clock session time without refetching
  /// this snapshot every tick. For timed games, [GameTradingViewData.tradingDeadlineUtc]
  /// carries `games.end_time_decided`; [CountdownTimer] recomputes each tick from that
  /// instant so all devices stay aligned with the server field.
  ///
  /// Copied from [tradingViewData].
  const TradingViewDataFamily();

  /// Trading dashboard snapshot for [gameId] (Phase 2B.5).
  ///
  /// Does **not** subscribe to the timer tick for its AsyncNotifier rebuild.
  /// [GameTradingViewData.chartSessionElapsed] is therefore a snapshot when the
  /// payload was built. The live trading route passes
  /// [GameTradingScreen.liveChartSessionElapsed] from [chartSessionElapsedProvider]
  /// so the price chart advances with wall-clock session time without refetching
  /// this snapshot every tick. For timed games, [GameTradingViewData.tradingDeadlineUtc]
  /// carries `games.end_time_decided`; [CountdownTimer] recomputes each tick from that
  /// instant so all devices stay aligned with the server field.
  ///
  /// Copied from [tradingViewData].
  TradingViewDataProvider call(String gameId) {
    return TradingViewDataProvider(gameId);
  }

  @override
  TradingViewDataProvider getProviderOverride(
    covariant TradingViewDataProvider provider,
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
  String? get name => r'tradingViewDataProvider';
}

/// Trading dashboard snapshot for [gameId] (Phase 2B.5).
///
/// Does **not** subscribe to the timer tick for its AsyncNotifier rebuild.
/// [GameTradingViewData.chartSessionElapsed] is therefore a snapshot when the
/// payload was built. The live trading route passes
/// [GameTradingScreen.liveChartSessionElapsed] from [chartSessionElapsedProvider]
/// so the price chart advances with wall-clock session time without refetching
/// this snapshot every tick. For timed games, [GameTradingViewData.tradingDeadlineUtc]
/// carries `games.end_time_decided`; [CountdownTimer] recomputes each tick from that
/// instant so all devices stay aligned with the server field.
///
/// Copied from [tradingViewData].
class TradingViewDataProvider
    extends AutoDisposeFutureProvider<GameTradingViewData> {
  /// Trading dashboard snapshot for [gameId] (Phase 2B.5).
  ///
  /// Does **not** subscribe to the timer tick for its AsyncNotifier rebuild.
  /// [GameTradingViewData.chartSessionElapsed] is therefore a snapshot when the
  /// payload was built. The live trading route passes
  /// [GameTradingScreen.liveChartSessionElapsed] from [chartSessionElapsedProvider]
  /// so the price chart advances with wall-clock session time without refetching
  /// this snapshot every tick. For timed games, [GameTradingViewData.tradingDeadlineUtc]
  /// carries `games.end_time_decided`; [CountdownTimer] recomputes each tick from that
  /// instant so all devices stay aligned with the server field.
  ///
  /// Copied from [tradingViewData].
  TradingViewDataProvider(String gameId)
    : this._internal(
        (ref) => tradingViewData(ref as TradingViewDataRef, gameId),
        from: tradingViewDataProvider,
        name: r'tradingViewDataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$tradingViewDataHash,
        dependencies: TradingViewDataFamily._dependencies,
        allTransitiveDependencies:
            TradingViewDataFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  TradingViewDataProvider._internal(
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
    FutureOr<GameTradingViewData> Function(TradingViewDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TradingViewDataProvider._internal(
        (ref) => create(ref as TradingViewDataRef),
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
  AutoDisposeFutureProviderElement<GameTradingViewData> createElement() {
    return _TradingViewDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TradingViewDataProvider && other.gameId == gameId;
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
mixin TradingViewDataRef on AutoDisposeFutureProviderRef<GameTradingViewData> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _TradingViewDataProviderElement
    extends AutoDisposeFutureProviderElement<GameTradingViewData>
    with TradingViewDataRef {
  _TradingViewDataProviderElement(super.provider);

  @override
  String get gameId => (origin as TradingViewDataProvider).gameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
