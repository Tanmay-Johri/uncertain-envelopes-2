// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_realtime_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gameRealtimeSessionHash() =>
    r'5d4f93c477b70bacbd3824bdaa860cf7765089a3';

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

/// Starts [GameRealtimeService] for [gameId] while this provider is watched,
/// and disposes it when no longer watched.
///
/// No-op when [useRealBackend] is `false` (default in-memory stack), when
/// [gameId] is empty, or when Supabase has not finished initializing.
///
/// Copied from [gameRealtimeSession].
@ProviderFor(gameRealtimeSession)
const gameRealtimeSessionProvider = GameRealtimeSessionFamily();

/// Starts [GameRealtimeService] for [gameId] while this provider is watched,
/// and disposes it when no longer watched.
///
/// No-op when [useRealBackend] is `false` (default in-memory stack), when
/// [gameId] is empty, or when Supabase has not finished initializing.
///
/// Copied from [gameRealtimeSession].
class GameRealtimeSessionFamily extends Family<void> {
  /// Starts [GameRealtimeService] for [gameId] while this provider is watched,
  /// and disposes it when no longer watched.
  ///
  /// No-op when [useRealBackend] is `false` (default in-memory stack), when
  /// [gameId] is empty, or when Supabase has not finished initializing.
  ///
  /// Copied from [gameRealtimeSession].
  const GameRealtimeSessionFamily();

  /// Starts [GameRealtimeService] for [gameId] while this provider is watched,
  /// and disposes it when no longer watched.
  ///
  /// No-op when [useRealBackend] is `false` (default in-memory stack), when
  /// [gameId] is empty, or when Supabase has not finished initializing.
  ///
  /// Copied from [gameRealtimeSession].
  GameRealtimeSessionProvider call(String gameId) {
    return GameRealtimeSessionProvider(gameId);
  }

  @override
  GameRealtimeSessionProvider getProviderOverride(
    covariant GameRealtimeSessionProvider provider,
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
  String? get name => r'gameRealtimeSessionProvider';
}

/// Starts [GameRealtimeService] for [gameId] while this provider is watched,
/// and disposes it when no longer watched.
///
/// No-op when [useRealBackend] is `false` (default in-memory stack), when
/// [gameId] is empty, or when Supabase has not finished initializing.
///
/// Copied from [gameRealtimeSession].
class GameRealtimeSessionProvider extends AutoDisposeProvider<void> {
  /// Starts [GameRealtimeService] for [gameId] while this provider is watched,
  /// and disposes it when no longer watched.
  ///
  /// No-op when [useRealBackend] is `false` (default in-memory stack), when
  /// [gameId] is empty, or when Supabase has not finished initializing.
  ///
  /// Copied from [gameRealtimeSession].
  GameRealtimeSessionProvider(String gameId)
    : this._internal(
        (ref) => gameRealtimeSession(ref as GameRealtimeSessionRef, gameId),
        from: gameRealtimeSessionProvider,
        name: r'gameRealtimeSessionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$gameRealtimeSessionHash,
        dependencies: GameRealtimeSessionFamily._dependencies,
        allTransitiveDependencies:
            GameRealtimeSessionFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  GameRealtimeSessionProvider._internal(
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
  Override overrideWith(void Function(GameRealtimeSessionRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: GameRealtimeSessionProvider._internal(
        (ref) => create(ref as GameRealtimeSessionRef),
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
  AutoDisposeProviderElement<void> createElement() {
    return _GameRealtimeSessionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GameRealtimeSessionProvider && other.gameId == gameId;
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
mixin GameRealtimeSessionRef on AutoDisposeProviderRef<void> {
  /// The parameter `gameId` of this provider.
  String get gameId;
}

class _GameRealtimeSessionProviderElement
    extends AutoDisposeProviderElement<void>
    with GameRealtimeSessionRef {
  _GameRealtimeSessionProviderElement(super.provider);

  @override
  String get gameId => (origin as GameRealtimeSessionProvider).gameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
