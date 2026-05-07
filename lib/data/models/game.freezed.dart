// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Game _$GameFromJson(Map<String, dynamic> json) {
  return _Game.fromJson(json);
}

/// @nodoc
mixin _$Game {
  @JsonKey(name: 'game_id')
  String get gameId => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_name')
  String get gameName => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_description')
  String? get gameDescription => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_created_at')
  DateTime get gameCreatedAt => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'game_security',
    fromJson: GameSecurity.fromWire,
    toJson: GameSecurity.toWire,
  )
  GameSecurity get gameSecurity => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'is_ranked',
    fromJson: IsRanked.fromWire,
    toJson: IsRanked.toWire,
  )
  IsRanked get isRanked => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_max_players')
  int get gameMaxPlayers => throw _privateConstructorUsedError;
  @JsonKey(name: 'joining_code')
  String get joiningCode => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'end_condition',
    fromJson: EndCondition.fromWire,
    toJson: EndCondition.toWire,
  )
  EndCondition get endCondition => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_decided_duration_seconds')
  int? get totalDecidedDurationSeconds => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time_decided')
  DateTime? get endTimeDecided => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  DateTime? get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time_actual')
  DateTime? get endTimeActual => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'game_state',
    fromJson: GameState.fromWire,
    toJson: GameState.toWire,
  )
  GameState get gameState => throw _privateConstructorUsedError;
  @JsonKey(name: 'admin_player_id')
  String get adminPlayerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_traded_price')
  double? get lastTradedPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'envelope_price')
  double? get envelopePrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'state_version')
  int get stateVersion => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Game to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GameCopyWith<Game> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameCopyWith<$Res> {
  factory $GameCopyWith(Game value, $Res Function(Game) then) =
      _$GameCopyWithImpl<$Res, Game>;
  @useResult
  $Res call({
    @JsonKey(name: 'game_id') String gameId,
    @JsonKey(name: 'game_name') String gameName,
    @JsonKey(name: 'game_description') String? gameDescription,
    @JsonKey(name: 'game_created_at') DateTime gameCreatedAt,
    @JsonKey(
      name: 'game_security',
      fromJson: GameSecurity.fromWire,
      toJson: GameSecurity.toWire,
    )
    GameSecurity gameSecurity,
    @JsonKey(
      name: 'is_ranked',
      fromJson: IsRanked.fromWire,
      toJson: IsRanked.toWire,
    )
    IsRanked isRanked,
    @JsonKey(name: 'game_max_players') int gameMaxPlayers,
    @JsonKey(name: 'joining_code') String joiningCode,
    @JsonKey(
      name: 'end_condition',
      fromJson: EndCondition.fromWire,
      toJson: EndCondition.toWire,
    )
    EndCondition endCondition,
    @JsonKey(name: 'total_decided_duration_seconds')
    int? totalDecidedDurationSeconds,
    @JsonKey(name: 'end_time_decided') DateTime? endTimeDecided,
    @JsonKey(name: 'start_time') DateTime? startTime,
    @JsonKey(name: 'end_time_actual') DateTime? endTimeActual,
    @JsonKey(
      name: 'game_state',
      fromJson: GameState.fromWire,
      toJson: GameState.toWire,
    )
    GameState gameState,
    @JsonKey(name: 'admin_player_id') String adminPlayerId,
    @JsonKey(name: 'last_traded_price') double? lastTradedPrice,
    @JsonKey(name: 'envelope_price') double? envelopePrice,
    @JsonKey(name: 'state_version') int stateVersion,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
  });
}

/// @nodoc
class _$GameCopyWithImpl<$Res, $Val extends Game>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? gameName = null,
    Object? gameDescription = freezed,
    Object? gameCreatedAt = null,
    Object? gameSecurity = null,
    Object? isRanked = null,
    Object? gameMaxPlayers = null,
    Object? joiningCode = null,
    Object? endCondition = null,
    Object? totalDecidedDurationSeconds = freezed,
    Object? endTimeDecided = freezed,
    Object? startTime = freezed,
    Object? endTimeActual = freezed,
    Object? gameState = null,
    Object? adminPlayerId = null,
    Object? lastTradedPrice = freezed,
    Object? envelopePrice = freezed,
    Object? stateVersion = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            gameName: null == gameName
                ? _value.gameName
                : gameName // ignore: cast_nullable_to_non_nullable
                      as String,
            gameDescription: freezed == gameDescription
                ? _value.gameDescription
                : gameDescription // ignore: cast_nullable_to_non_nullable
                      as String?,
            gameCreatedAt: null == gameCreatedAt
                ? _value.gameCreatedAt
                : gameCreatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            gameSecurity: null == gameSecurity
                ? _value.gameSecurity
                : gameSecurity // ignore: cast_nullable_to_non_nullable
                      as GameSecurity,
            isRanked: null == isRanked
                ? _value.isRanked
                : isRanked // ignore: cast_nullable_to_non_nullable
                      as IsRanked,
            gameMaxPlayers: null == gameMaxPlayers
                ? _value.gameMaxPlayers
                : gameMaxPlayers // ignore: cast_nullable_to_non_nullable
                      as int,
            joiningCode: null == joiningCode
                ? _value.joiningCode
                : joiningCode // ignore: cast_nullable_to_non_nullable
                      as String,
            endCondition: null == endCondition
                ? _value.endCondition
                : endCondition // ignore: cast_nullable_to_non_nullable
                      as EndCondition,
            totalDecidedDurationSeconds: freezed == totalDecidedDurationSeconds
                ? _value.totalDecidedDurationSeconds
                : totalDecidedDurationSeconds // ignore: cast_nullable_to_non_nullable
                      as int?,
            endTimeDecided: freezed == endTimeDecided
                ? _value.endTimeDecided
                : endTimeDecided // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            startTime: freezed == startTime
                ? _value.startTime
                : startTime // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            endTimeActual: freezed == endTimeActual
                ? _value.endTimeActual
                : endTimeActual // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            gameState: null == gameState
                ? _value.gameState
                : gameState // ignore: cast_nullable_to_non_nullable
                      as GameState,
            adminPlayerId: null == adminPlayerId
                ? _value.adminPlayerId
                : adminPlayerId // ignore: cast_nullable_to_non_nullable
                      as String,
            lastTradedPrice: freezed == lastTradedPrice
                ? _value.lastTradedPrice
                : lastTradedPrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            envelopePrice: freezed == envelopePrice
                ? _value.envelopePrice
                : envelopePrice // ignore: cast_nullable_to_non_nullable
                      as double?,
            stateVersion: null == stateVersion
                ? _value.stateVersion
                : stateVersion // ignore: cast_nullable_to_non_nullable
                      as int,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GameImplCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$$GameImplCopyWith(
    _$GameImpl value,
    $Res Function(_$GameImpl) then,
  ) = __$$GameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'game_id') String gameId,
    @JsonKey(name: 'game_name') String gameName,
    @JsonKey(name: 'game_description') String? gameDescription,
    @JsonKey(name: 'game_created_at') DateTime gameCreatedAt,
    @JsonKey(
      name: 'game_security',
      fromJson: GameSecurity.fromWire,
      toJson: GameSecurity.toWire,
    )
    GameSecurity gameSecurity,
    @JsonKey(
      name: 'is_ranked',
      fromJson: IsRanked.fromWire,
      toJson: IsRanked.toWire,
    )
    IsRanked isRanked,
    @JsonKey(name: 'game_max_players') int gameMaxPlayers,
    @JsonKey(name: 'joining_code') String joiningCode,
    @JsonKey(
      name: 'end_condition',
      fromJson: EndCondition.fromWire,
      toJson: EndCondition.toWire,
    )
    EndCondition endCondition,
    @JsonKey(name: 'total_decided_duration_seconds')
    int? totalDecidedDurationSeconds,
    @JsonKey(name: 'end_time_decided') DateTime? endTimeDecided,
    @JsonKey(name: 'start_time') DateTime? startTime,
    @JsonKey(name: 'end_time_actual') DateTime? endTimeActual,
    @JsonKey(
      name: 'game_state',
      fromJson: GameState.fromWire,
      toJson: GameState.toWire,
    )
    GameState gameState,
    @JsonKey(name: 'admin_player_id') String adminPlayerId,
    @JsonKey(name: 'last_traded_price') double? lastTradedPrice,
    @JsonKey(name: 'envelope_price') double? envelopePrice,
    @JsonKey(name: 'state_version') int stateVersion,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
  });
}

/// @nodoc
class __$$GameImplCopyWithImpl<$Res>
    extends _$GameCopyWithImpl<$Res, _$GameImpl>
    implements _$$GameImplCopyWith<$Res> {
  __$$GameImplCopyWithImpl(_$GameImpl _value, $Res Function(_$GameImpl) _then)
    : super(_value, _then);

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? gameName = null,
    Object? gameDescription = freezed,
    Object? gameCreatedAt = null,
    Object? gameSecurity = null,
    Object? isRanked = null,
    Object? gameMaxPlayers = null,
    Object? joiningCode = null,
    Object? endCondition = null,
    Object? totalDecidedDurationSeconds = freezed,
    Object? endTimeDecided = freezed,
    Object? startTime = freezed,
    Object? endTimeActual = freezed,
    Object? gameState = null,
    Object? adminPlayerId = null,
    Object? lastTradedPrice = freezed,
    Object? envelopePrice = freezed,
    Object? stateVersion = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$GameImpl(
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        gameName: null == gameName
            ? _value.gameName
            : gameName // ignore: cast_nullable_to_non_nullable
                  as String,
        gameDescription: freezed == gameDescription
            ? _value.gameDescription
            : gameDescription // ignore: cast_nullable_to_non_nullable
                  as String?,
        gameCreatedAt: null == gameCreatedAt
            ? _value.gameCreatedAt
            : gameCreatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        gameSecurity: null == gameSecurity
            ? _value.gameSecurity
            : gameSecurity // ignore: cast_nullable_to_non_nullable
                  as GameSecurity,
        isRanked: null == isRanked
            ? _value.isRanked
            : isRanked // ignore: cast_nullable_to_non_nullable
                  as IsRanked,
        gameMaxPlayers: null == gameMaxPlayers
            ? _value.gameMaxPlayers
            : gameMaxPlayers // ignore: cast_nullable_to_non_nullable
                  as int,
        joiningCode: null == joiningCode
            ? _value.joiningCode
            : joiningCode // ignore: cast_nullable_to_non_nullable
                  as String,
        endCondition: null == endCondition
            ? _value.endCondition
            : endCondition // ignore: cast_nullable_to_non_nullable
                  as EndCondition,
        totalDecidedDurationSeconds: freezed == totalDecidedDurationSeconds
            ? _value.totalDecidedDurationSeconds
            : totalDecidedDurationSeconds // ignore: cast_nullable_to_non_nullable
                  as int?,
        endTimeDecided: freezed == endTimeDecided
            ? _value.endTimeDecided
            : endTimeDecided // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        startTime: freezed == startTime
            ? _value.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        endTimeActual: freezed == endTimeActual
            ? _value.endTimeActual
            : endTimeActual // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        gameState: null == gameState
            ? _value.gameState
            : gameState // ignore: cast_nullable_to_non_nullable
                  as GameState,
        adminPlayerId: null == adminPlayerId
            ? _value.adminPlayerId
            : adminPlayerId // ignore: cast_nullable_to_non_nullable
                  as String,
        lastTradedPrice: freezed == lastTradedPrice
            ? _value.lastTradedPrice
            : lastTradedPrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        envelopePrice: freezed == envelopePrice
            ? _value.envelopePrice
            : envelopePrice // ignore: cast_nullable_to_non_nullable
                  as double?,
        stateVersion: null == stateVersion
            ? _value.stateVersion
            : stateVersion // ignore: cast_nullable_to_non_nullable
                  as int,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GameImpl implements _Game {
  const _$GameImpl({
    @JsonKey(name: 'game_id') required this.gameId,
    @JsonKey(name: 'game_name') required this.gameName,
    @JsonKey(name: 'game_description') this.gameDescription,
    @JsonKey(name: 'game_created_at') required this.gameCreatedAt,
    @JsonKey(
      name: 'game_security',
      fromJson: GameSecurity.fromWire,
      toJson: GameSecurity.toWire,
    )
    required this.gameSecurity,
    @JsonKey(
      name: 'is_ranked',
      fromJson: IsRanked.fromWire,
      toJson: IsRanked.toWire,
    )
    required this.isRanked,
    @JsonKey(name: 'game_max_players') required this.gameMaxPlayers,
    @JsonKey(name: 'joining_code') required this.joiningCode,
    @JsonKey(
      name: 'end_condition',
      fromJson: EndCondition.fromWire,
      toJson: EndCondition.toWire,
    )
    required this.endCondition,
    @JsonKey(name: 'total_decided_duration_seconds')
    this.totalDecidedDurationSeconds,
    @JsonKey(name: 'end_time_decided') this.endTimeDecided,
    @JsonKey(name: 'start_time') this.startTime,
    @JsonKey(name: 'end_time_actual') this.endTimeActual,
    @JsonKey(
      name: 'game_state',
      fromJson: GameState.fromWire,
      toJson: GameState.toWire,
    )
    required this.gameState,
    @JsonKey(name: 'admin_player_id') required this.adminPlayerId,
    @JsonKey(name: 'last_traded_price') this.lastTradedPrice,
    @JsonKey(name: 'envelope_price') this.envelopePrice,
    @JsonKey(name: 'state_version') required this.stateVersion,
    @JsonKey(name: 'updated_at') required this.updatedAt,
  });

  factory _$GameImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameImplFromJson(json);

  @override
  @JsonKey(name: 'game_id')
  final String gameId;
  @override
  @JsonKey(name: 'game_name')
  final String gameName;
  @override
  @JsonKey(name: 'game_description')
  final String? gameDescription;
  @override
  @JsonKey(name: 'game_created_at')
  final DateTime gameCreatedAt;
  @override
  @JsonKey(
    name: 'game_security',
    fromJson: GameSecurity.fromWire,
    toJson: GameSecurity.toWire,
  )
  final GameSecurity gameSecurity;
  @override
  @JsonKey(
    name: 'is_ranked',
    fromJson: IsRanked.fromWire,
    toJson: IsRanked.toWire,
  )
  final IsRanked isRanked;
  @override
  @JsonKey(name: 'game_max_players')
  final int gameMaxPlayers;
  @override
  @JsonKey(name: 'joining_code')
  final String joiningCode;
  @override
  @JsonKey(
    name: 'end_condition',
    fromJson: EndCondition.fromWire,
    toJson: EndCondition.toWire,
  )
  final EndCondition endCondition;
  @override
  @JsonKey(name: 'total_decided_duration_seconds')
  final int? totalDecidedDurationSeconds;
  @override
  @JsonKey(name: 'end_time_decided')
  final DateTime? endTimeDecided;
  @override
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  @override
  @JsonKey(name: 'end_time_actual')
  final DateTime? endTimeActual;
  @override
  @JsonKey(
    name: 'game_state',
    fromJson: GameState.fromWire,
    toJson: GameState.toWire,
  )
  final GameState gameState;
  @override
  @JsonKey(name: 'admin_player_id')
  final String adminPlayerId;
  @override
  @JsonKey(name: 'last_traded_price')
  final double? lastTradedPrice;
  @override
  @JsonKey(name: 'envelope_price')
  final double? envelopePrice;
  @override
  @JsonKey(name: 'state_version')
  final int stateVersion;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Game(gameId: $gameId, gameName: $gameName, gameDescription: $gameDescription, gameCreatedAt: $gameCreatedAt, gameSecurity: $gameSecurity, isRanked: $isRanked, gameMaxPlayers: $gameMaxPlayers, joiningCode: $joiningCode, endCondition: $endCondition, totalDecidedDurationSeconds: $totalDecidedDurationSeconds, endTimeDecided: $endTimeDecided, startTime: $startTime, endTimeActual: $endTimeActual, gameState: $gameState, adminPlayerId: $adminPlayerId, lastTradedPrice: $lastTradedPrice, envelopePrice: $envelopePrice, stateVersion: $stateVersion, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.gameName, gameName) ||
                other.gameName == gameName) &&
            (identical(other.gameDescription, gameDescription) ||
                other.gameDescription == gameDescription) &&
            (identical(other.gameCreatedAt, gameCreatedAt) ||
                other.gameCreatedAt == gameCreatedAt) &&
            (identical(other.gameSecurity, gameSecurity) ||
                other.gameSecurity == gameSecurity) &&
            (identical(other.isRanked, isRanked) ||
                other.isRanked == isRanked) &&
            (identical(other.gameMaxPlayers, gameMaxPlayers) ||
                other.gameMaxPlayers == gameMaxPlayers) &&
            (identical(other.joiningCode, joiningCode) ||
                other.joiningCode == joiningCode) &&
            (identical(other.endCondition, endCondition) ||
                other.endCondition == endCondition) &&
            (identical(
                  other.totalDecidedDurationSeconds,
                  totalDecidedDurationSeconds,
                ) ||
                other.totalDecidedDurationSeconds ==
                    totalDecidedDurationSeconds) &&
            (identical(other.endTimeDecided, endTimeDecided) ||
                other.endTimeDecided == endTimeDecided) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTimeActual, endTimeActual) ||
                other.endTimeActual == endTimeActual) &&
            (identical(other.gameState, gameState) ||
                other.gameState == gameState) &&
            (identical(other.adminPlayerId, adminPlayerId) ||
                other.adminPlayerId == adminPlayerId) &&
            (identical(other.lastTradedPrice, lastTradedPrice) ||
                other.lastTradedPrice == lastTradedPrice) &&
            (identical(other.envelopePrice, envelopePrice) ||
                other.envelopePrice == envelopePrice) &&
            (identical(other.stateVersion, stateVersion) ||
                other.stateVersion == stateVersion) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    gameId,
    gameName,
    gameDescription,
    gameCreatedAt,
    gameSecurity,
    isRanked,
    gameMaxPlayers,
    joiningCode,
    endCondition,
    totalDecidedDurationSeconds,
    endTimeDecided,
    startTime,
    endTimeActual,
    gameState,
    adminPlayerId,
    lastTradedPrice,
    envelopePrice,
    stateVersion,
    updatedAt,
  ]);

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      __$$GameImplCopyWithImpl<_$GameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameImplToJson(this);
  }
}

abstract class _Game implements Game {
  const factory _Game({
    @JsonKey(name: 'game_id') required final String gameId,
    @JsonKey(name: 'game_name') required final String gameName,
    @JsonKey(name: 'game_description') final String? gameDescription,
    @JsonKey(name: 'game_created_at') required final DateTime gameCreatedAt,
    @JsonKey(
      name: 'game_security',
      fromJson: GameSecurity.fromWire,
      toJson: GameSecurity.toWire,
    )
    required final GameSecurity gameSecurity,
    @JsonKey(
      name: 'is_ranked',
      fromJson: IsRanked.fromWire,
      toJson: IsRanked.toWire,
    )
    required final IsRanked isRanked,
    @JsonKey(name: 'game_max_players') required final int gameMaxPlayers,
    @JsonKey(name: 'joining_code') required final String joiningCode,
    @JsonKey(
      name: 'end_condition',
      fromJson: EndCondition.fromWire,
      toJson: EndCondition.toWire,
    )
    required final EndCondition endCondition,
    @JsonKey(name: 'total_decided_duration_seconds')
    final int? totalDecidedDurationSeconds,
    @JsonKey(name: 'end_time_decided') final DateTime? endTimeDecided,
    @JsonKey(name: 'start_time') final DateTime? startTime,
    @JsonKey(name: 'end_time_actual') final DateTime? endTimeActual,
    @JsonKey(
      name: 'game_state',
      fromJson: GameState.fromWire,
      toJson: GameState.toWire,
    )
    required final GameState gameState,
    @JsonKey(name: 'admin_player_id') required final String adminPlayerId,
    @JsonKey(name: 'last_traded_price') final double? lastTradedPrice,
    @JsonKey(name: 'envelope_price') final double? envelopePrice,
    @JsonKey(name: 'state_version') required final int stateVersion,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
  }) = _$GameImpl;

  factory _Game.fromJson(Map<String, dynamic> json) = _$GameImpl.fromJson;

  @override
  @JsonKey(name: 'game_id')
  String get gameId;
  @override
  @JsonKey(name: 'game_name')
  String get gameName;
  @override
  @JsonKey(name: 'game_description')
  String? get gameDescription;
  @override
  @JsonKey(name: 'game_created_at')
  DateTime get gameCreatedAt;
  @override
  @JsonKey(
    name: 'game_security',
    fromJson: GameSecurity.fromWire,
    toJson: GameSecurity.toWire,
  )
  GameSecurity get gameSecurity;
  @override
  @JsonKey(
    name: 'is_ranked',
    fromJson: IsRanked.fromWire,
    toJson: IsRanked.toWire,
  )
  IsRanked get isRanked;
  @override
  @JsonKey(name: 'game_max_players')
  int get gameMaxPlayers;
  @override
  @JsonKey(name: 'joining_code')
  String get joiningCode;
  @override
  @JsonKey(
    name: 'end_condition',
    fromJson: EndCondition.fromWire,
    toJson: EndCondition.toWire,
  )
  EndCondition get endCondition;
  @override
  @JsonKey(name: 'total_decided_duration_seconds')
  int? get totalDecidedDurationSeconds;
  @override
  @JsonKey(name: 'end_time_decided')
  DateTime? get endTimeDecided;
  @override
  @JsonKey(name: 'start_time')
  DateTime? get startTime;
  @override
  @JsonKey(name: 'end_time_actual')
  DateTime? get endTimeActual;
  @override
  @JsonKey(
    name: 'game_state',
    fromJson: GameState.fromWire,
    toJson: GameState.toWire,
  )
  GameState get gameState;
  @override
  @JsonKey(name: 'admin_player_id')
  String get adminPlayerId;
  @override
  @JsonKey(name: 'last_traded_price')
  double? get lastTradedPrice;
  @override
  @JsonKey(name: 'envelope_price')
  double? get envelopePrice;
  @override
  @JsonKey(name: 'state_version')
  int get stateVersion;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of Game
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
