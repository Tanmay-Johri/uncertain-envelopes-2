// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lobbyPlayersHash() => r'ffbd7f0c0e92b68a244b9be38240224908ca2a2d';

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

/// Just the lobby players list, sorted by `joined_at` ascending so the UI
/// shows players in join order. Returns an empty list while the snapshot
/// is still loading so the UI can show a skeleton without null-checking.
///
/// Copied from [lobbyPlayers].
@ProviderFor(lobbyPlayers)
const lobbyPlayersProvider = LobbyPlayersFamily();

/// Just the lobby players list, sorted by `joined_at` ascending so the UI
/// shows players in join order. Returns an empty list while the snapshot
/// is still loading so the UI can show a skeleton without null-checking.
///
/// Copied from [lobbyPlayers].
class LobbyPlayersFamily extends Family<List<GamePlayer>> {
  /// Just the lobby players list, sorted by `joined_at` ascending so the UI
  /// shows players in join order. Returns an empty list while the snapshot
  /// is still loading so the UI can show a skeleton without null-checking.
  ///
  /// Copied from [lobbyPlayers].
  const LobbyPlayersFamily();

  /// Just the lobby players list, sorted by `joined_at` ascending so the UI
  /// shows players in join order. Returns an empty list while the snapshot
  /// is still loading so the UI can show a skeleton without null-checking.
  ///
  /// Copied from [lobbyPlayers].
  LobbyPlayersProvider call(String gameId) {
    return LobbyPlayersProvider(gameId);
  }

  @override
  LobbyPlayersProvider getProviderOverride(
    covariant LobbyPlayersProvider provider,
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
  String? get name => r'lobbyPlayersProvider';
}

/// Just the lobby players list, sorted by `joined_at` ascending so the UI
/// shows players in join order. Returns an empty list while the snapshot
/// is still loading so the UI can show a skeleton without null-checking.
///
/// Copied from [lobbyPlayers].
class LobbyPlayersProvider extends AutoDisposeProvider<List<GamePlayer>> {
  /// Just the lobby players list, sorted by `joined_at` ascending so the UI
  /// shows players in join order. Returns an empty list while the snapshot
  /// is still loading so the UI can show a skeleton without null-checking.
  ///
  /// Copied from [lobbyPlayers].
  LobbyPlayersProvider(String gameId)
    : this._internal(
        (ref) => lobbyPlayers(ref as LobbyPlayersRef, gameId),
        from: lobbyPlayersProvider,
        name: r'lobbyPlayersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$lobbyPlayersHash,
        dependencies: LobbyPlayersFamily._dependencies,
        allTransitiveDependencies:
            LobbyPlayersFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  LobbyPlayersProvider._internal(
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
    List<GamePlayer> Function(LobbyPlayersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LobbyPlayersProvider._internal(
        (ref) => create(ref as LobbyPlayersRef),
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
  AutoDisposeProviderElement<List<GamePlayer>> createElement() {
    return _LobbyPlayersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LobbyPlayersProvider && other.gameId == gameId;
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
mixin LobbyPlayersRef on AutoDisposeProviderRef<List<GamePlayer>> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _LobbyPlayersProviderElement
    extends AutoDisposeProviderElement<List<GamePlayer>>
    with LobbyPlayersRef {
  _LobbyPlayersProviderElement(super.provider);

  @override
  String get gameId => (origin as LobbyPlayersProvider).gameId;
}

String _$gameSecondsRemainingHash() =>
    r'bf65375bcb432fa1fd49a9dd4f187986f6802729';

/// Seconds remaining in a timed game. Semantics:
///   - Returns null when the game has not loaded yet.
///   - Returns null for endless games or timed games with no
///     `end_time_decided` (i.e. the game has not started).
///   - Returns >= 0 otherwise; clamped to 0 when the deadline has passed.
///
/// Reactivity: recomputes on every tick of [timerTickStreamProvider] and
/// on every change to [currentGameProvider] (so `add_time` updates are
/// reflected within one tick).
///
/// Copied from [gameSecondsRemaining].
@ProviderFor(gameSecondsRemaining)
const gameSecondsRemainingProvider = GameSecondsRemainingFamily();

/// Seconds remaining in a timed game. Semantics:
///   - Returns null when the game has not loaded yet.
///   - Returns null for endless games or timed games with no
///     `end_time_decided` (i.e. the game has not started).
///   - Returns >= 0 otherwise; clamped to 0 when the deadline has passed.
///
/// Reactivity: recomputes on every tick of [timerTickStreamProvider] and
/// on every change to [currentGameProvider] (so `add_time` updates are
/// reflected within one tick).
///
/// Copied from [gameSecondsRemaining].
class GameSecondsRemainingFamily extends Family<int?> {
  /// Seconds remaining in a timed game. Semantics:
  ///   - Returns null when the game has not loaded yet.
  ///   - Returns null for endless games or timed games with no
  ///     `end_time_decided` (i.e. the game has not started).
  ///   - Returns >= 0 otherwise; clamped to 0 when the deadline has passed.
  ///
  /// Reactivity: recomputes on every tick of [timerTickStreamProvider] and
  /// on every change to [currentGameProvider] (so `add_time` updates are
  /// reflected within one tick).
  ///
  /// Copied from [gameSecondsRemaining].
  const GameSecondsRemainingFamily();

  /// Seconds remaining in a timed game. Semantics:
  ///   - Returns null when the game has not loaded yet.
  ///   - Returns null for endless games or timed games with no
  ///     `end_time_decided` (i.e. the game has not started).
  ///   - Returns >= 0 otherwise; clamped to 0 when the deadline has passed.
  ///
  /// Reactivity: recomputes on every tick of [timerTickStreamProvider] and
  /// on every change to [currentGameProvider] (so `add_time` updates are
  /// reflected within one tick).
  ///
  /// Copied from [gameSecondsRemaining].
  GameSecondsRemainingProvider call(String gameId) {
    return GameSecondsRemainingProvider(gameId);
  }

  @override
  GameSecondsRemainingProvider getProviderOverride(
    covariant GameSecondsRemainingProvider provider,
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
  String? get name => r'gameSecondsRemainingProvider';
}

/// Seconds remaining in a timed game. Semantics:
///   - Returns null when the game has not loaded yet.
///   - Returns null for endless games or timed games with no
///     `end_time_decided` (i.e. the game has not started).
///   - Returns >= 0 otherwise; clamped to 0 when the deadline has passed.
///
/// Reactivity: recomputes on every tick of [timerTickStreamProvider] and
/// on every change to [currentGameProvider] (so `add_time` updates are
/// reflected within one tick).
///
/// Copied from [gameSecondsRemaining].
class GameSecondsRemainingProvider extends AutoDisposeProvider<int?> {
  /// Seconds remaining in a timed game. Semantics:
  ///   - Returns null when the game has not loaded yet.
  ///   - Returns null for endless games or timed games with no
  ///     `end_time_decided` (i.e. the game has not started).
  ///   - Returns >= 0 otherwise; clamped to 0 when the deadline has passed.
  ///
  /// Reactivity: recomputes on every tick of [timerTickStreamProvider] and
  /// on every change to [currentGameProvider] (so `add_time` updates are
  /// reflected within one tick).
  ///
  /// Copied from [gameSecondsRemaining].
  GameSecondsRemainingProvider(String gameId)
    : this._internal(
        (ref) => gameSecondsRemaining(ref as GameSecondsRemainingRef, gameId),
        from: gameSecondsRemainingProvider,
        name: r'gameSecondsRemainingProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$gameSecondsRemainingHash,
        dependencies: GameSecondsRemainingFamily._dependencies,
        allTransitiveDependencies:
            GameSecondsRemainingFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  GameSecondsRemainingProvider._internal(
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
    int? Function(GameSecondsRemainingRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GameSecondsRemainingProvider._internal(
        (ref) => create(ref as GameSecondsRemainingRef),
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
  AutoDisposeProviderElement<int?> createElement() {
    return _GameSecondsRemainingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GameSecondsRemainingProvider && other.gameId == gameId;
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
mixin GameSecondsRemainingRef on AutoDisposeProviderRef<int?> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _GameSecondsRemainingProviderElement
    extends AutoDisposeProviderElement<int?>
    with GameSecondsRemainingRef {
  _GameSecondsRemainingProviderElement(super.provider);

  @override
  String get gameId => (origin as GameSecondsRemainingProvider).gameId;
}

String _$currentGameHash() => r'9c1999bcbe3de26961597c1cb00c4c5391038dbe';

abstract class _$CurrentGame
    extends BuildlessAutoDisposeAsyncNotifier<GameSessionState> {
  late final String gameId;

  FutureOr<GameSessionState> build(String gameId);
}

/// Fetches the full game + players snapshot and exposes mutation hooks
/// used by the realtime service (B10) to apply realtime deltas.
///
/// Copied from [CurrentGame].
@ProviderFor(CurrentGame)
const currentGameProvider = CurrentGameFamily();

/// Fetches the full game + players snapshot and exposes mutation hooks
/// used by the realtime service (B10) to apply realtime deltas.
///
/// Copied from [CurrentGame].
class CurrentGameFamily extends Family<AsyncValue<GameSessionState>> {
  /// Fetches the full game + players snapshot and exposes mutation hooks
  /// used by the realtime service (B10) to apply realtime deltas.
  ///
  /// Copied from [CurrentGame].
  const CurrentGameFamily();

  /// Fetches the full game + players snapshot and exposes mutation hooks
  /// used by the realtime service (B10) to apply realtime deltas.
  ///
  /// Copied from [CurrentGame].
  CurrentGameProvider call(String gameId) {
    return CurrentGameProvider(gameId);
  }

  @override
  CurrentGameProvider getProviderOverride(
    covariant CurrentGameProvider provider,
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
  String? get name => r'currentGameProvider';
}

/// Fetches the full game + players snapshot and exposes mutation hooks
/// used by the realtime service (B10) to apply realtime deltas.
///
/// Copied from [CurrentGame].
class CurrentGameProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<CurrentGame, GameSessionState> {
  /// Fetches the full game + players snapshot and exposes mutation hooks
  /// used by the realtime service (B10) to apply realtime deltas.
  ///
  /// Copied from [CurrentGame].
  CurrentGameProvider(String gameId)
    : this._internal(
        () => CurrentGame()..gameId = gameId,
        from: currentGameProvider,
        name: r'currentGameProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentGameHash,
        dependencies: CurrentGameFamily._dependencies,
        allTransitiveDependencies: CurrentGameFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  CurrentGameProvider._internal(
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
  FutureOr<GameSessionState> runNotifierBuild(covariant CurrentGame notifier) {
    return notifier.build(gameId);
  }

  @override
  Override overrideWith(CurrentGame Function() create) {
    return ProviderOverride(
      origin: this,
      override: CurrentGameProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<CurrentGame, GameSessionState>
  createElement() {
    return _CurrentGameProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentGameProvider && other.gameId == gameId;
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
mixin CurrentGameRef on AutoDisposeAsyncNotifierProviderRef<GameSessionState> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _CurrentGameProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<CurrentGame, GameSessionState>
    with CurrentGameRef {
  _CurrentGameProviderElement(super.provider);

  @override
  String get gameId => (origin as CurrentGameProvider).gameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
