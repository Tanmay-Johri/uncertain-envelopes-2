// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trading_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orderBookHash() => r'c3c04755442413909ca959605623ad0c8e2866be';

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

/// Aggregated resting-order book: bids desc by price, asks asc by price.
///
/// Only orders with status [OrderStatus.orderResting] and a non-null
/// `pricePerStock` participate. Market orders never rest, so they are
/// implicitly excluded.
///
/// Copied from [orderBook].
@ProviderFor(orderBook)
const orderBookProvider = OrderBookFamily();

/// Aggregated resting-order book: bids desc by price, asks asc by price.
///
/// Only orders with status [OrderStatus.orderResting] and a non-null
/// `pricePerStock` participate. Market orders never rest, so they are
/// implicitly excluded.
///
/// Copied from [orderBook].
class OrderBookFamily extends Family<OrderBook> {
  /// Aggregated resting-order book: bids desc by price, asks asc by price.
  ///
  /// Only orders with status [OrderStatus.orderResting] and a non-null
  /// `pricePerStock` participate. Market orders never rest, so they are
  /// implicitly excluded.
  ///
  /// Copied from [orderBook].
  const OrderBookFamily();

  /// Aggregated resting-order book: bids desc by price, asks asc by price.
  ///
  /// Only orders with status [OrderStatus.orderResting] and a non-null
  /// `pricePerStock` participate. Market orders never rest, so they are
  /// implicitly excluded.
  ///
  /// Copied from [orderBook].
  OrderBookProvider call(String gameId) {
    return OrderBookProvider(gameId);
  }

  @override
  OrderBookProvider getProviderOverride(covariant OrderBookProvider provider) {
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
  String? get name => r'orderBookProvider';
}

/// Aggregated resting-order book: bids desc by price, asks asc by price.
///
/// Only orders with status [OrderStatus.orderResting] and a non-null
/// `pricePerStock` participate. Market orders never rest, so they are
/// implicitly excluded.
///
/// Copied from [orderBook].
class OrderBookProvider extends AutoDisposeProvider<OrderBook> {
  /// Aggregated resting-order book: bids desc by price, asks asc by price.
  ///
  /// Only orders with status [OrderStatus.orderResting] and a non-null
  /// `pricePerStock` participate. Market orders never rest, so they are
  /// implicitly excluded.
  ///
  /// Copied from [orderBook].
  OrderBookProvider(String gameId)
    : this._internal(
        (ref) => orderBook(ref as OrderBookRef, gameId),
        from: orderBookProvider,
        name: r'orderBookProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$orderBookHash,
        dependencies: OrderBookFamily._dependencies,
        allTransitiveDependencies: OrderBookFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  OrderBookProvider._internal(
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
  Override overrideWith(OrderBook Function(OrderBookRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: OrderBookProvider._internal(
        (ref) => create(ref as OrderBookRef),
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
  AutoDisposeProviderElement<OrderBook> createElement() {
    return _OrderBookProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrderBookProvider && other.gameId == gameId;
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
mixin OrderBookRef on AutoDisposeProviderRef<OrderBook> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _OrderBookProviderElement extends AutoDisposeProviderElement<OrderBook>
    with OrderBookRef {
  _OrderBookProviderElement(super.provider);

  @override
  String get gameId => (origin as OrderBookProvider).gameId;
}

String _$personalOrdersHash() => r'409a0ce46f9f645db898af2d23f22ca88f524606';

/// Orders belonging to [playerId] within [gameId]. Sorted newest first,
/// per PRD §Personal Orders intent.
///
/// Known gap: the PRD also wants pending `create_order` commands that
/// have not yet produced an orders row to show up as "in queue"
/// placeholders. That requires a command-status fetch we haven't
/// wired yet; tracked separately. This provider currently surfaces
/// only the orders table.
///
/// Copied from [personalOrders].
@ProviderFor(personalOrders)
const personalOrdersProvider = PersonalOrdersFamily();

/// Orders belonging to [playerId] within [gameId]. Sorted newest first,
/// per PRD §Personal Orders intent.
///
/// Known gap: the PRD also wants pending `create_order` commands that
/// have not yet produced an orders row to show up as "in queue"
/// placeholders. That requires a command-status fetch we haven't
/// wired yet; tracked separately. This provider currently surfaces
/// only the orders table.
///
/// Copied from [personalOrders].
class PersonalOrdersFamily extends Family<List<Order>> {
  /// Orders belonging to [playerId] within [gameId]. Sorted newest first,
  /// per PRD §Personal Orders intent.
  ///
  /// Known gap: the PRD also wants pending `create_order` commands that
  /// have not yet produced an orders row to show up as "in queue"
  /// placeholders. That requires a command-status fetch we haven't
  /// wired yet; tracked separately. This provider currently surfaces
  /// only the orders table.
  ///
  /// Copied from [personalOrders].
  const PersonalOrdersFamily();

  /// Orders belonging to [playerId] within [gameId]. Sorted newest first,
  /// per PRD §Personal Orders intent.
  ///
  /// Known gap: the PRD also wants pending `create_order` commands that
  /// have not yet produced an orders row to show up as "in queue"
  /// placeholders. That requires a command-status fetch we haven't
  /// wired yet; tracked separately. This provider currently surfaces
  /// only the orders table.
  ///
  /// Copied from [personalOrders].
  PersonalOrdersProvider call({
    required String gameId,
    required String playerId,
  }) {
    return PersonalOrdersProvider(gameId: gameId, playerId: playerId);
  }

  @override
  PersonalOrdersProvider getProviderOverride(
    covariant PersonalOrdersProvider provider,
  ) {
    return call(gameId: provider.gameId, playerId: provider.playerId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'personalOrdersProvider';
}

/// Orders belonging to [playerId] within [gameId]. Sorted newest first,
/// per PRD §Personal Orders intent.
///
/// Known gap: the PRD also wants pending `create_order` commands that
/// have not yet produced an orders row to show up as "in queue"
/// placeholders. That requires a command-status fetch we haven't
/// wired yet; tracked separately. This provider currently surfaces
/// only the orders table.
///
/// Copied from [personalOrders].
class PersonalOrdersProvider extends AutoDisposeProvider<List<Order>> {
  /// Orders belonging to [playerId] within [gameId]. Sorted newest first,
  /// per PRD §Personal Orders intent.
  ///
  /// Known gap: the PRD also wants pending `create_order` commands that
  /// have not yet produced an orders row to show up as "in queue"
  /// placeholders. That requires a command-status fetch we haven't
  /// wired yet; tracked separately. This provider currently surfaces
  /// only the orders table.
  ///
  /// Copied from [personalOrders].
  PersonalOrdersProvider({required String gameId, required String playerId})
    : this._internal(
        (ref) => personalOrders(
          ref as PersonalOrdersRef,
          gameId: gameId,
          playerId: playerId,
        ),
        from: personalOrdersProvider,
        name: r'personalOrdersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$personalOrdersHash,
        dependencies: PersonalOrdersFamily._dependencies,
        allTransitiveDependencies:
            PersonalOrdersFamily._allTransitiveDependencies,
        gameId: gameId,
        playerId: playerId,
      );

  PersonalOrdersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.gameId,
    required this.playerId,
  }) : super.internal();

  final String gameId;
  final String playerId;

  @override
  Override overrideWith(
    List<Order> Function(PersonalOrdersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PersonalOrdersProvider._internal(
        (ref) => create(ref as PersonalOrdersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        gameId: gameId,
        playerId: playerId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<List<Order>> createElement() {
    return _PersonalOrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PersonalOrdersProvider &&
        other.gameId == gameId &&
        other.playerId == playerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, gameId.hashCode);
    hash = _SystemHash.combine(hash, playerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PersonalOrdersRef on AutoDisposeProviderRef<List<Order>> {
  /// The parameter `gameId` of this provider.
  String get gameId;

  /// The parameter `playerId` of this provider.
  String get playerId;
}

class _PersonalOrdersProviderElement
    extends AutoDisposeProviderElement<List<Order>>
    with PersonalOrdersRef {
  _PersonalOrdersProviderElement(super.provider);

  @override
  String get gameId => (origin as PersonalOrdersProvider).gameId;
  @override
  String get playerId => (origin as PersonalOrdersProvider).playerId;
}

String _$executionHistoryHash() => r'fe07cad5c3f7aaa56217f27b184ba072bff90e93';

/// (timeElapsed, price) datapoints for the trading chart. Returns an
/// empty list when the game has not started yet (no start_time), when
/// the snapshot is still loading, or when no executions exist yet.
///
/// Emits the canonical [PriceChartPoint] type owned by `lib/core/chart/`,
/// which is also what [PriceChart] (the UI widget) consumes — so the
/// provider output flows straight into the chart with no conversion.
///
/// Copied from [executionHistory].
@ProviderFor(executionHistory)
const executionHistoryProvider = ExecutionHistoryFamily();

/// (timeElapsed, price) datapoints for the trading chart. Returns an
/// empty list when the game has not started yet (no start_time), when
/// the snapshot is still loading, or when no executions exist yet.
///
/// Emits the canonical [PriceChartPoint] type owned by `lib/core/chart/`,
/// which is also what [PriceChart] (the UI widget) consumes — so the
/// provider output flows straight into the chart with no conversion.
///
/// Copied from [executionHistory].
class ExecutionHistoryFamily extends Family<List<PriceChartPoint>> {
  /// (timeElapsed, price) datapoints for the trading chart. Returns an
  /// empty list when the game has not started yet (no start_time), when
  /// the snapshot is still loading, or when no executions exist yet.
  ///
  /// Emits the canonical [PriceChartPoint] type owned by `lib/core/chart/`,
  /// which is also what [PriceChart] (the UI widget) consumes — so the
  /// provider output flows straight into the chart with no conversion.
  ///
  /// Copied from [executionHistory].
  const ExecutionHistoryFamily();

  /// (timeElapsed, price) datapoints for the trading chart. Returns an
  /// empty list when the game has not started yet (no start_time), when
  /// the snapshot is still loading, or when no executions exist yet.
  ///
  /// Emits the canonical [PriceChartPoint] type owned by `lib/core/chart/`,
  /// which is also what [PriceChart] (the UI widget) consumes — so the
  /// provider output flows straight into the chart with no conversion.
  ///
  /// Copied from [executionHistory].
  ExecutionHistoryProvider call(String gameId) {
    return ExecutionHistoryProvider(gameId);
  }

  @override
  ExecutionHistoryProvider getProviderOverride(
    covariant ExecutionHistoryProvider provider,
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
  String? get name => r'executionHistoryProvider';
}

/// (timeElapsed, price) datapoints for the trading chart. Returns an
/// empty list when the game has not started yet (no start_time), when
/// the snapshot is still loading, or when no executions exist yet.
///
/// Emits the canonical [PriceChartPoint] type owned by `lib/core/chart/`,
/// which is also what [PriceChart] (the UI widget) consumes — so the
/// provider output flows straight into the chart with no conversion.
///
/// Copied from [executionHistory].
class ExecutionHistoryProvider
    extends AutoDisposeProvider<List<PriceChartPoint>> {
  /// (timeElapsed, price) datapoints for the trading chart. Returns an
  /// empty list when the game has not started yet (no start_time), when
  /// the snapshot is still loading, or when no executions exist yet.
  ///
  /// Emits the canonical [PriceChartPoint] type owned by `lib/core/chart/`,
  /// which is also what [PriceChart] (the UI widget) consumes — so the
  /// provider output flows straight into the chart with no conversion.
  ///
  /// Copied from [executionHistory].
  ExecutionHistoryProvider(String gameId)
    : this._internal(
        (ref) => executionHistory(ref as ExecutionHistoryRef, gameId),
        from: executionHistoryProvider,
        name: r'executionHistoryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$executionHistoryHash,
        dependencies: ExecutionHistoryFamily._dependencies,
        allTransitiveDependencies:
            ExecutionHistoryFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  ExecutionHistoryProvider._internal(
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
    List<PriceChartPoint> Function(ExecutionHistoryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ExecutionHistoryProvider._internal(
        (ref) => create(ref as ExecutionHistoryRef),
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
  AutoDisposeProviderElement<List<PriceChartPoint>> createElement() {
    return _ExecutionHistoryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExecutionHistoryProvider && other.gameId == gameId;
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
mixin ExecutionHistoryRef on AutoDisposeProviderRef<List<PriceChartPoint>> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _ExecutionHistoryProviderElement
    extends AutoDisposeProviderElement<List<PriceChartPoint>>
    with ExecutionHistoryRef {
  _ExecutionHistoryProviderElement(super.provider);

  @override
  String get gameId => (origin as ExecutionHistoryProvider).gameId;
}

String _$chartSessionElapsedHash() =>
    r'f5113500cccf4e8d3b85b5576b428d34c4267ba3';

/// Wall-clock elapsed time the chart should cover (the "session" duration).
///
/// PRD elapsed rules:
/// - Before start_time exists: synthesise 1 minute so the axis renders.
/// - While trading is active: elapsed = now() - start_time
/// - After trading ended: elapsed = end_time_actual - start_time
///
/// Exposed as its own provider (not just inlined in [chartAxis]) because
/// `GameTradingViewData.chartSessionElapsed` consumes exactly this value
/// at INT1 wiring time, and [PriceChart] derives its tooltip x-axis from
/// the same number.
///
/// Copied from [chartSessionElapsed].
@ProviderFor(chartSessionElapsed)
const chartSessionElapsedProvider = ChartSessionElapsedFamily();

/// Wall-clock elapsed time the chart should cover (the "session" duration).
///
/// PRD elapsed rules:
/// - Before start_time exists: synthesise 1 minute so the axis renders.
/// - While trading is active: elapsed = now() - start_time
/// - After trading ended: elapsed = end_time_actual - start_time
///
/// Exposed as its own provider (not just inlined in [chartAxis]) because
/// `GameTradingViewData.chartSessionElapsed` consumes exactly this value
/// at INT1 wiring time, and [PriceChart] derives its tooltip x-axis from
/// the same number.
///
/// Copied from [chartSessionElapsed].
class ChartSessionElapsedFamily extends Family<Duration> {
  /// Wall-clock elapsed time the chart should cover (the "session" duration).
  ///
  /// PRD elapsed rules:
  /// - Before start_time exists: synthesise 1 minute so the axis renders.
  /// - While trading is active: elapsed = now() - start_time
  /// - After trading ended: elapsed = end_time_actual - start_time
  ///
  /// Exposed as its own provider (not just inlined in [chartAxis]) because
  /// `GameTradingViewData.chartSessionElapsed` consumes exactly this value
  /// at INT1 wiring time, and [PriceChart] derives its tooltip x-axis from
  /// the same number.
  ///
  /// Copied from [chartSessionElapsed].
  const ChartSessionElapsedFamily();

  /// Wall-clock elapsed time the chart should cover (the "session" duration).
  ///
  /// PRD elapsed rules:
  /// - Before start_time exists: synthesise 1 minute so the axis renders.
  /// - While trading is active: elapsed = now() - start_time
  /// - After trading ended: elapsed = end_time_actual - start_time
  ///
  /// Exposed as its own provider (not just inlined in [chartAxis]) because
  /// `GameTradingViewData.chartSessionElapsed` consumes exactly this value
  /// at INT1 wiring time, and [PriceChart] derives its tooltip x-axis from
  /// the same number.
  ///
  /// Copied from [chartSessionElapsed].
  ChartSessionElapsedProvider call(String gameId) {
    return ChartSessionElapsedProvider(gameId);
  }

  @override
  ChartSessionElapsedProvider getProviderOverride(
    covariant ChartSessionElapsedProvider provider,
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
  String? get name => r'chartSessionElapsedProvider';
}

/// Wall-clock elapsed time the chart should cover (the "session" duration).
///
/// PRD elapsed rules:
/// - Before start_time exists: synthesise 1 minute so the axis renders.
/// - While trading is active: elapsed = now() - start_time
/// - After trading ended: elapsed = end_time_actual - start_time
///
/// Exposed as its own provider (not just inlined in [chartAxis]) because
/// `GameTradingViewData.chartSessionElapsed` consumes exactly this value
/// at INT1 wiring time, and [PriceChart] derives its tooltip x-axis from
/// the same number.
///
/// Copied from [chartSessionElapsed].
class ChartSessionElapsedProvider extends AutoDisposeProvider<Duration> {
  /// Wall-clock elapsed time the chart should cover (the "session" duration).
  ///
  /// PRD elapsed rules:
  /// - Before start_time exists: synthesise 1 minute so the axis renders.
  /// - While trading is active: elapsed = now() - start_time
  /// - After trading ended: elapsed = end_time_actual - start_time
  ///
  /// Exposed as its own provider (not just inlined in [chartAxis]) because
  /// `GameTradingViewData.chartSessionElapsed` consumes exactly this value
  /// at INT1 wiring time, and [PriceChart] derives its tooltip x-axis from
  /// the same number.
  ///
  /// Copied from [chartSessionElapsed].
  ChartSessionElapsedProvider(String gameId)
    : this._internal(
        (ref) => chartSessionElapsed(ref as ChartSessionElapsedRef, gameId),
        from: chartSessionElapsedProvider,
        name: r'chartSessionElapsedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chartSessionElapsedHash,
        dependencies: ChartSessionElapsedFamily._dependencies,
        allTransitiveDependencies:
            ChartSessionElapsedFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  ChartSessionElapsedProvider._internal(
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
    Duration Function(ChartSessionElapsedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChartSessionElapsedProvider._internal(
        (ref) => create(ref as ChartSessionElapsedRef),
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
  AutoDisposeProviderElement<Duration> createElement() {
    return _ChartSessionElapsedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChartSessionElapsedProvider && other.gameId == gameId;
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
mixin ChartSessionElapsedRef on AutoDisposeProviderRef<Duration> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _ChartSessionElapsedProviderElement
    extends AutoDisposeProviderElement<Duration>
    with ChartSessionElapsedRef {
  _ChartSessionElapsedProviderElement(super.provider);

  @override
  String get gameId => (origin as ChartSessionElapsedProvider).gameId;
}

String _$chartAxisHash() => r'b5382f0d36c3af38fdbbf4049e4a809054ba7344';

/// Chart axis configuration derived from executionHistory + session
/// elapsed time. Delegates to [ChartAxisConfig.fromExecutionHistory] —
/// the same factory the trading screen calls inline today — so the
/// provider-driven path is byte-identical to the mock-driven path the
/// UI was tuned against.
///
/// Copied from [chartAxis].
@ProviderFor(chartAxis)
const chartAxisProvider = ChartAxisFamily();

/// Chart axis configuration derived from executionHistory + session
/// elapsed time. Delegates to [ChartAxisConfig.fromExecutionHistory] —
/// the same factory the trading screen calls inline today — so the
/// provider-driven path is byte-identical to the mock-driven path the
/// UI was tuned against.
///
/// Copied from [chartAxis].
class ChartAxisFamily extends Family<ChartAxisConfig> {
  /// Chart axis configuration derived from executionHistory + session
  /// elapsed time. Delegates to [ChartAxisConfig.fromExecutionHistory] —
  /// the same factory the trading screen calls inline today — so the
  /// provider-driven path is byte-identical to the mock-driven path the
  /// UI was tuned against.
  ///
  /// Copied from [chartAxis].
  const ChartAxisFamily();

  /// Chart axis configuration derived from executionHistory + session
  /// elapsed time. Delegates to [ChartAxisConfig.fromExecutionHistory] —
  /// the same factory the trading screen calls inline today — so the
  /// provider-driven path is byte-identical to the mock-driven path the
  /// UI was tuned against.
  ///
  /// Copied from [chartAxis].
  ChartAxisProvider call(String gameId) {
    return ChartAxisProvider(gameId);
  }

  @override
  ChartAxisProvider getProviderOverride(covariant ChartAxisProvider provider) {
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
  String? get name => r'chartAxisProvider';
}

/// Chart axis configuration derived from executionHistory + session
/// elapsed time. Delegates to [ChartAxisConfig.fromExecutionHistory] —
/// the same factory the trading screen calls inline today — so the
/// provider-driven path is byte-identical to the mock-driven path the
/// UI was tuned against.
///
/// Copied from [chartAxis].
class ChartAxisProvider extends AutoDisposeProvider<ChartAxisConfig> {
  /// Chart axis configuration derived from executionHistory + session
  /// elapsed time. Delegates to [ChartAxisConfig.fromExecutionHistory] —
  /// the same factory the trading screen calls inline today — so the
  /// provider-driven path is byte-identical to the mock-driven path the
  /// UI was tuned against.
  ///
  /// Copied from [chartAxis].
  ChartAxisProvider(String gameId)
    : this._internal(
        (ref) => chartAxis(ref as ChartAxisRef, gameId),
        from: chartAxisProvider,
        name: r'chartAxisProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chartAxisHash,
        dependencies: ChartAxisFamily._dependencies,
        allTransitiveDependencies: ChartAxisFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  ChartAxisProvider._internal(
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
    ChartAxisConfig Function(ChartAxisRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChartAxisProvider._internal(
        (ref) => create(ref as ChartAxisRef),
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
  AutoDisposeProviderElement<ChartAxisConfig> createElement() {
    return _ChartAxisProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChartAxisProvider && other.gameId == gameId;
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
mixin ChartAxisRef on AutoDisposeProviderRef<ChartAxisConfig> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _ChartAxisProviderElement
    extends AutoDisposeProviderElement<ChartAxisConfig>
    with ChartAxisRef {
  _ChartAxisProviderElement(super.provider);

  @override
  String get gameId => (origin as ChartAxisProvider).gameId;
}

String _$ordersHash() => r'2da170fda193bff965df763ec77e0ee936ed145f';

abstract class _$Orders extends BuildlessAutoDisposeAsyncNotifier<List<Order>> {
  late final String gameId;

  FutureOr<List<Order>> build(String gameId);
}

/// All orders for a game. Fed initially by [OrderRepository], then updated
/// by [GameRealtimeService] (B10) via the mutation hooks below.
///
/// Copied from [Orders].
@ProviderFor(Orders)
const ordersProvider = OrdersFamily();

/// All orders for a game. Fed initially by [OrderRepository], then updated
/// by [GameRealtimeService] (B10) via the mutation hooks below.
///
/// Copied from [Orders].
class OrdersFamily extends Family<AsyncValue<List<Order>>> {
  /// All orders for a game. Fed initially by [OrderRepository], then updated
  /// by [GameRealtimeService] (B10) via the mutation hooks below.
  ///
  /// Copied from [Orders].
  const OrdersFamily();

  /// All orders for a game. Fed initially by [OrderRepository], then updated
  /// by [GameRealtimeService] (B10) via the mutation hooks below.
  ///
  /// Copied from [Orders].
  OrdersProvider call(String gameId) {
    return OrdersProvider(gameId);
  }

  @override
  OrdersProvider getProviderOverride(covariant OrdersProvider provider) {
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
  String? get name => r'ordersProvider';
}

/// All orders for a game. Fed initially by [OrderRepository], then updated
/// by [GameRealtimeService] (B10) via the mutation hooks below.
///
/// Copied from [Orders].
class OrdersProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Orders, List<Order>> {
  /// All orders for a game. Fed initially by [OrderRepository], then updated
  /// by [GameRealtimeService] (B10) via the mutation hooks below.
  ///
  /// Copied from [Orders].
  OrdersProvider(String gameId)
    : this._internal(
        () => Orders()..gameId = gameId,
        from: ordersProvider,
        name: r'ordersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$ordersHash,
        dependencies: OrdersFamily._dependencies,
        allTransitiveDependencies: OrdersFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  OrdersProvider._internal(
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
  FutureOr<List<Order>> runNotifierBuild(covariant Orders notifier) {
    return notifier.build(gameId);
  }

  @override
  Override overrideWith(Orders Function() create) {
    return ProviderOverride(
      origin: this,
      override: OrdersProvider._internal(
        () => create()..gameId = gameId,
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
  AutoDisposeAsyncNotifierProviderElement<Orders, List<Order>> createElement() {
    return _OrdersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OrdersProvider && other.gameId == gameId;
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
mixin OrdersRef on AutoDisposeAsyncNotifierProviderRef<List<Order>> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _OrdersProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Orders, List<Order>>
    with OrdersRef {
  _OrdersProviderElement(super.provider);

  @override
  String get gameId => (origin as OrdersProvider).gameId;
}

String _$executionsHash() => r'05b61473e82d150441d915e7612f7bd37b4202f7';

abstract class _$Executions
    extends BuildlessAutoDisposeAsyncNotifier<List<Execution>> {
  late final String gameId;

  FutureOr<List<Execution>> build(String gameId);
}

/// All executions for a game, sorted ascending by `executed_at`.
///
/// Copied from [Executions].
@ProviderFor(Executions)
const executionsProvider = ExecutionsFamily();

/// All executions for a game, sorted ascending by `executed_at`.
///
/// Copied from [Executions].
class ExecutionsFamily extends Family<AsyncValue<List<Execution>>> {
  /// All executions for a game, sorted ascending by `executed_at`.
  ///
  /// Copied from [Executions].
  const ExecutionsFamily();

  /// All executions for a game, sorted ascending by `executed_at`.
  ///
  /// Copied from [Executions].
  ExecutionsProvider call(String gameId) {
    return ExecutionsProvider(gameId);
  }

  @override
  ExecutionsProvider getProviderOverride(
    covariant ExecutionsProvider provider,
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
  String? get name => r'executionsProvider';
}

/// All executions for a game, sorted ascending by `executed_at`.
///
/// Copied from [Executions].
class ExecutionsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Executions, List<Execution>> {
  /// All executions for a game, sorted ascending by `executed_at`.
  ///
  /// Copied from [Executions].
  ExecutionsProvider(String gameId)
    : this._internal(
        () => Executions()..gameId = gameId,
        from: executionsProvider,
        name: r'executionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$executionsHash,
        dependencies: ExecutionsFamily._dependencies,
        allTransitiveDependencies: ExecutionsFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  ExecutionsProvider._internal(
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
  FutureOr<List<Execution>> runNotifierBuild(covariant Executions notifier) {
    return notifier.build(gameId);
  }

  @override
  Override overrideWith(Executions Function() create) {
    return ProviderOverride(
      origin: this,
      override: ExecutionsProvider._internal(
        () => create()..gameId = gameId,
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
  AutoDisposeAsyncNotifierProviderElement<Executions, List<Execution>>
  createElement() {
    return _ExecutionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ExecutionsProvider && other.gameId == gameId;
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
mixin ExecutionsRef on AutoDisposeAsyncNotifierProviderRef<List<Execution>> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _ExecutionsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Executions, List<Execution>>
    with ExecutionsRef {
  _ExecutionsProviderElement(super.provider);

  @override
  String get gameId => (origin as ExecutionsProvider).gameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
