// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lobby_view_data_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lobbyViewDataHash() => r'8a2ae5bee7867a8726819d049865b3ebd27aeaea';

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

/// Lobby header, roster, and phase for [gameId] (Phase 2B.4).
///
/// Does **not** subscribe to the timer tick so the future runs only when
/// session data changes (auth / realtime / membership). The countdown is
/// rendered by the `CountdownTimer` widget which ticks locally from a
/// one-shot seconds-remaining snapshot read here.
///
/// Copied from [lobbyViewData].
@ProviderFor(lobbyViewData)
const lobbyViewDataProvider = LobbyViewDataFamily();

/// Lobby header, roster, and phase for [gameId] (Phase 2B.4).
///
/// Does **not** subscribe to the timer tick so the future runs only when
/// session data changes (auth / realtime / membership). The countdown is
/// rendered by the `CountdownTimer` widget which ticks locally from a
/// one-shot seconds-remaining snapshot read here.
///
/// Copied from [lobbyViewData].
class LobbyViewDataFamily extends Family<AsyncValue<GameLobbyScenario>> {
  /// Lobby header, roster, and phase for [gameId] (Phase 2B.4).
  ///
  /// Does **not** subscribe to the timer tick so the future runs only when
  /// session data changes (auth / realtime / membership). The countdown is
  /// rendered by the `CountdownTimer` widget which ticks locally from a
  /// one-shot seconds-remaining snapshot read here.
  ///
  /// Copied from [lobbyViewData].
  const LobbyViewDataFamily();

  /// Lobby header, roster, and phase for [gameId] (Phase 2B.4).
  ///
  /// Does **not** subscribe to the timer tick so the future runs only when
  /// session data changes (auth / realtime / membership). The countdown is
  /// rendered by the `CountdownTimer` widget which ticks locally from a
  /// one-shot seconds-remaining snapshot read here.
  ///
  /// Copied from [lobbyViewData].
  LobbyViewDataProvider call(String gameId) {
    return LobbyViewDataProvider(gameId);
  }

  @override
  LobbyViewDataProvider getProviderOverride(
    covariant LobbyViewDataProvider provider,
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
  String? get name => r'lobbyViewDataProvider';
}

/// Lobby header, roster, and phase for [gameId] (Phase 2B.4).
///
/// Does **not** subscribe to the timer tick so the future runs only when
/// session data changes (auth / realtime / membership). The countdown is
/// rendered by the `CountdownTimer` widget which ticks locally from a
/// one-shot seconds-remaining snapshot read here.
///
/// Copied from [lobbyViewData].
class LobbyViewDataProvider
    extends AutoDisposeFutureProvider<GameLobbyScenario> {
  /// Lobby header, roster, and phase for [gameId] (Phase 2B.4).
  ///
  /// Does **not** subscribe to the timer tick so the future runs only when
  /// session data changes (auth / realtime / membership). The countdown is
  /// rendered by the `CountdownTimer` widget which ticks locally from a
  /// one-shot seconds-remaining snapshot read here.
  ///
  /// Copied from [lobbyViewData].
  LobbyViewDataProvider(String gameId)
    : this._internal(
        (ref) => lobbyViewData(ref as LobbyViewDataRef, gameId),
        from: lobbyViewDataProvider,
        name: r'lobbyViewDataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$lobbyViewDataHash,
        dependencies: LobbyViewDataFamily._dependencies,
        allTransitiveDependencies:
            LobbyViewDataFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  LobbyViewDataProvider._internal(
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
    FutureOr<GameLobbyScenario> Function(LobbyViewDataRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LobbyViewDataProvider._internal(
        (ref) => create(ref as LobbyViewDataRef),
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
  AutoDisposeFutureProviderElement<GameLobbyScenario> createElement() {
    return _LobbyViewDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyViewDataProvider && other.gameId == gameId;
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
mixin LobbyViewDataRef on AutoDisposeFutureProviderRef<GameLobbyScenario> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _LobbyViewDataProviderElement
    extends AutoDisposeFutureProviderElement<GameLobbyScenario>
    with LobbyViewDataRef {
  _LobbyViewDataProviderElement(super.provider);

  @override
  String get gameId => (origin as LobbyViewDataProvider).gameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
