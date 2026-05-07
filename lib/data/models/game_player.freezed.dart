// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GamePlayer _$GamePlayerFromJson(Map<String, dynamic> json) {
  return _GamePlayer.fromJson(json);
}

/// @nodoc
mixin _$GamePlayer {
  @JsonKey(name: 'games_players_row_id')
  String get gamesPlayersRowId => throw _privateConstructorUsedError;
  @JsonKey(name: 'map_game_id')
  String get mapGameId => throw _privateConstructorUsedError;
  @JsonKey(name: 'map_player_id')
  String get mapPlayerId => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'lobby_status',
    fromJson: LobbyStatus.fromWire,
    toJson: LobbyStatus.toWire,
  )
  LobbyStatus get lobbyStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'joined_at')
  DateTime get joinedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_admin')
  bool get isAdmin => throw _privateConstructorUsedError;
  @JsonKey(name: 'delta_cash')
  double get deltaCash => throw _privateConstructorUsedError;
  @JsonKey(name: 'delta_envelopes')
  int get deltaEnvelopes => throw _privateConstructorUsedError;
  @JsonKey(name: 'pnl')
  double get pnl => throw _privateConstructorUsedError;

  /// Serializes this GamePlayer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GamePlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GamePlayerCopyWith<GamePlayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GamePlayerCopyWith<$Res> {
  factory $GamePlayerCopyWith(
    GamePlayer value,
    $Res Function(GamePlayer) then,
  ) = _$GamePlayerCopyWithImpl<$Res, GamePlayer>;
  @useResult
  $Res call({
    @JsonKey(name: 'games_players_row_id') String gamesPlayersRowId,
    @JsonKey(name: 'map_game_id') String mapGameId,
    @JsonKey(name: 'map_player_id') String mapPlayerId,
    @JsonKey(
      name: 'lobby_status',
      fromJson: LobbyStatus.fromWire,
      toJson: LobbyStatus.toWire,
    )
    LobbyStatus lobbyStatus,
    @JsonKey(name: 'joined_at') DateTime joinedAt,
    @JsonKey(name: 'is_admin') bool isAdmin,
    @JsonKey(name: 'delta_cash') double deltaCash,
    @JsonKey(name: 'delta_envelopes') int deltaEnvelopes,
    @JsonKey(name: 'pnl') double pnl,
  });
}

/// @nodoc
class _$GamePlayerCopyWithImpl<$Res, $Val extends GamePlayer>
    implements $GamePlayerCopyWith<$Res> {
  _$GamePlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GamePlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gamesPlayersRowId = null,
    Object? mapGameId = null,
    Object? mapPlayerId = null,
    Object? lobbyStatus = null,
    Object? joinedAt = null,
    Object? isAdmin = null,
    Object? deltaCash = null,
    Object? deltaEnvelopes = null,
    Object? pnl = null,
  }) {
    return _then(
      _value.copyWith(
            gamesPlayersRowId: null == gamesPlayersRowId
                ? _value.gamesPlayersRowId
                : gamesPlayersRowId // ignore: cast_nullable_to_non_nullable
                      as String,
            mapGameId: null == mapGameId
                ? _value.mapGameId
                : mapGameId // ignore: cast_nullable_to_non_nullable
                      as String,
            mapPlayerId: null == mapPlayerId
                ? _value.mapPlayerId
                : mapPlayerId // ignore: cast_nullable_to_non_nullable
                      as String,
            lobbyStatus: null == lobbyStatus
                ? _value.lobbyStatus
                : lobbyStatus // ignore: cast_nullable_to_non_nullable
                      as LobbyStatus,
            joinedAt: null == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isAdmin: null == isAdmin
                ? _value.isAdmin
                : isAdmin // ignore: cast_nullable_to_non_nullable
                      as bool,
            deltaCash: null == deltaCash
                ? _value.deltaCash
                : deltaCash // ignore: cast_nullable_to_non_nullable
                      as double,
            deltaEnvelopes: null == deltaEnvelopes
                ? _value.deltaEnvelopes
                : deltaEnvelopes // ignore: cast_nullable_to_non_nullable
                      as int,
            pnl: null == pnl
                ? _value.pnl
                : pnl // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GamePlayerImplCopyWith<$Res>
    implements $GamePlayerCopyWith<$Res> {
  factory _$$GamePlayerImplCopyWith(
    _$GamePlayerImpl value,
    $Res Function(_$GamePlayerImpl) then,
  ) = __$$GamePlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'games_players_row_id') String gamesPlayersRowId,
    @JsonKey(name: 'map_game_id') String mapGameId,
    @JsonKey(name: 'map_player_id') String mapPlayerId,
    @JsonKey(
      name: 'lobby_status',
      fromJson: LobbyStatus.fromWire,
      toJson: LobbyStatus.toWire,
    )
    LobbyStatus lobbyStatus,
    @JsonKey(name: 'joined_at') DateTime joinedAt,
    @JsonKey(name: 'is_admin') bool isAdmin,
    @JsonKey(name: 'delta_cash') double deltaCash,
    @JsonKey(name: 'delta_envelopes') int deltaEnvelopes,
    @JsonKey(name: 'pnl') double pnl,
  });
}

/// @nodoc
class __$$GamePlayerImplCopyWithImpl<$Res>
    extends _$GamePlayerCopyWithImpl<$Res, _$GamePlayerImpl>
    implements _$$GamePlayerImplCopyWith<$Res> {
  __$$GamePlayerImplCopyWithImpl(
    _$GamePlayerImpl _value,
    $Res Function(_$GamePlayerImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GamePlayer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gamesPlayersRowId = null,
    Object? mapGameId = null,
    Object? mapPlayerId = null,
    Object? lobbyStatus = null,
    Object? joinedAt = null,
    Object? isAdmin = null,
    Object? deltaCash = null,
    Object? deltaEnvelopes = null,
    Object? pnl = null,
  }) {
    return _then(
      _$GamePlayerImpl(
        gamesPlayersRowId: null == gamesPlayersRowId
            ? _value.gamesPlayersRowId
            : gamesPlayersRowId // ignore: cast_nullable_to_non_nullable
                  as String,
        mapGameId: null == mapGameId
            ? _value.mapGameId
            : mapGameId // ignore: cast_nullable_to_non_nullable
                  as String,
        mapPlayerId: null == mapPlayerId
            ? _value.mapPlayerId
            : mapPlayerId // ignore: cast_nullable_to_non_nullable
                  as String,
        lobbyStatus: null == lobbyStatus
            ? _value.lobbyStatus
            : lobbyStatus // ignore: cast_nullable_to_non_nullable
                  as LobbyStatus,
        joinedAt: null == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isAdmin: null == isAdmin
            ? _value.isAdmin
            : isAdmin // ignore: cast_nullable_to_non_nullable
                  as bool,
        deltaCash: null == deltaCash
            ? _value.deltaCash
            : deltaCash // ignore: cast_nullable_to_non_nullable
                  as double,
        deltaEnvelopes: null == deltaEnvelopes
            ? _value.deltaEnvelopes
            : deltaEnvelopes // ignore: cast_nullable_to_non_nullable
                  as int,
        pnl: null == pnl
            ? _value.pnl
            : pnl // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GamePlayerImpl implements _GamePlayer {
  const _$GamePlayerImpl({
    @JsonKey(name: 'games_players_row_id') required this.gamesPlayersRowId,
    @JsonKey(name: 'map_game_id') required this.mapGameId,
    @JsonKey(name: 'map_player_id') required this.mapPlayerId,
    @JsonKey(
      name: 'lobby_status',
      fromJson: LobbyStatus.fromWire,
      toJson: LobbyStatus.toWire,
    )
    required this.lobbyStatus,
    @JsonKey(name: 'joined_at') required this.joinedAt,
    @JsonKey(name: 'is_admin') required this.isAdmin,
    @JsonKey(name: 'delta_cash') required this.deltaCash,
    @JsonKey(name: 'delta_envelopes') required this.deltaEnvelopes,
    @JsonKey(name: 'pnl') required this.pnl,
  });

  factory _$GamePlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$GamePlayerImplFromJson(json);

  @override
  @JsonKey(name: 'games_players_row_id')
  final String gamesPlayersRowId;
  @override
  @JsonKey(name: 'map_game_id')
  final String mapGameId;
  @override
  @JsonKey(name: 'map_player_id')
  final String mapPlayerId;
  @override
  @JsonKey(
    name: 'lobby_status',
    fromJson: LobbyStatus.fromWire,
    toJson: LobbyStatus.toWire,
  )
  final LobbyStatus lobbyStatus;
  @override
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;
  @override
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @override
  @JsonKey(name: 'delta_cash')
  final double deltaCash;
  @override
  @JsonKey(name: 'delta_envelopes')
  final int deltaEnvelopes;
  @override
  @JsonKey(name: 'pnl')
  final double pnl;

  @override
  String toString() {
    return 'GamePlayer(gamesPlayersRowId: $gamesPlayersRowId, mapGameId: $mapGameId, mapPlayerId: $mapPlayerId, lobbyStatus: $lobbyStatus, joinedAt: $joinedAt, isAdmin: $isAdmin, deltaCash: $deltaCash, deltaEnvelopes: $deltaEnvelopes, pnl: $pnl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GamePlayerImpl &&
            (identical(other.gamesPlayersRowId, gamesPlayersRowId) ||
                other.gamesPlayersRowId == gamesPlayersRowId) &&
            (identical(other.mapGameId, mapGameId) ||
                other.mapGameId == mapGameId) &&
            (identical(other.mapPlayerId, mapPlayerId) ||
                other.mapPlayerId == mapPlayerId) &&
            (identical(other.lobbyStatus, lobbyStatus) ||
                other.lobbyStatus == lobbyStatus) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.deltaCash, deltaCash) ||
                other.deltaCash == deltaCash) &&
            (identical(other.deltaEnvelopes, deltaEnvelopes) ||
                other.deltaEnvelopes == deltaEnvelopes) &&
            (identical(other.pnl, pnl) || other.pnl == pnl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    gamesPlayersRowId,
    mapGameId,
    mapPlayerId,
    lobbyStatus,
    joinedAt,
    isAdmin,
    deltaCash,
    deltaEnvelopes,
    pnl,
  );

  /// Create a copy of GamePlayer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GamePlayerImplCopyWith<_$GamePlayerImpl> get copyWith =>
      __$$GamePlayerImplCopyWithImpl<_$GamePlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GamePlayerImplToJson(this);
  }
}

abstract class _GamePlayer implements GamePlayer {
  const factory _GamePlayer({
    @JsonKey(name: 'games_players_row_id')
    required final String gamesPlayersRowId,
    @JsonKey(name: 'map_game_id') required final String mapGameId,
    @JsonKey(name: 'map_player_id') required final String mapPlayerId,
    @JsonKey(
      name: 'lobby_status',
      fromJson: LobbyStatus.fromWire,
      toJson: LobbyStatus.toWire,
    )
    required final LobbyStatus lobbyStatus,
    @JsonKey(name: 'joined_at') required final DateTime joinedAt,
    @JsonKey(name: 'is_admin') required final bool isAdmin,
    @JsonKey(name: 'delta_cash') required final double deltaCash,
    @JsonKey(name: 'delta_envelopes') required final int deltaEnvelopes,
    @JsonKey(name: 'pnl') required final double pnl,
  }) = _$GamePlayerImpl;

  factory _GamePlayer.fromJson(Map<String, dynamic> json) =
      _$GamePlayerImpl.fromJson;

  @override
  @JsonKey(name: 'games_players_row_id')
  String get gamesPlayersRowId;
  @override
  @JsonKey(name: 'map_game_id')
  String get mapGameId;
  @override
  @JsonKey(name: 'map_player_id')
  String get mapPlayerId;
  @override
  @JsonKey(
    name: 'lobby_status',
    fromJson: LobbyStatus.fromWire,
    toJson: LobbyStatus.toWire,
  )
  LobbyStatus get lobbyStatus;
  @override
  @JsonKey(name: 'joined_at')
  DateTime get joinedAt;
  @override
  @JsonKey(name: 'is_admin')
  bool get isAdmin;
  @override
  @JsonKey(name: 'delta_cash')
  double get deltaCash;
  @override
  @JsonKey(name: 'delta_envelopes')
  int get deltaEnvelopes;
  @override
  @JsonKey(name: 'pnl')
  double get pnl;

  /// Create a copy of GamePlayer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GamePlayerImplCopyWith<_$GamePlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
