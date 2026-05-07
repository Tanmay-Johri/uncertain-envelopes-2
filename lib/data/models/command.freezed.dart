// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'command.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Command _$CommandFromJson(Map<String, dynamic> json) {
  return _Command.fromJson(json);
}

/// @nodoc
mixin _$Command {
  @JsonKey(name: 'command_id')
  String get commandId => throw _privateConstructorUsedError;
  @JsonKey(name: 'command_game_id')
  String? get commandGameId => throw _privateConstructorUsedError;
  @JsonKey(name: 'command_created_at')
  DateTime get commandCreatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'player_id')
  String? get playerId => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'command_type',
    fromJson: CommandType.fromWire,
    toJson: CommandType.toWire,
  )
  CommandType get commandType => throw _privateConstructorUsedError;
  @JsonKey(name: 'payload')
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'command_status',
    fromJson: CommandStatus.fromWire,
    toJson: CommandStatus.toWire,
  )
  CommandStatus get commandStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'claim_token')
  String? get claimToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'claimed_at')
  DateTime? get claimedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'attempt_count')
  int get attemptCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'finished_at')
  DateTime? get finishedAt => throw _privateConstructorUsedError;

  /// Serializes this Command to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommandCopyWith<Command> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommandCopyWith<$Res> {
  factory $CommandCopyWith(Command value, $Res Function(Command) then) =
      _$CommandCopyWithImpl<$Res, Command>;
  @useResult
  $Res call({
    @JsonKey(name: 'command_id') String commandId,
    @JsonKey(name: 'command_game_id') String? commandGameId,
    @JsonKey(name: 'command_created_at') DateTime commandCreatedAt,
    @JsonKey(name: 'player_id') String? playerId,
    @JsonKey(
      name: 'command_type',
      fromJson: CommandType.fromWire,
      toJson: CommandType.toWire,
    )
    CommandType commandType,
    @JsonKey(name: 'payload') Map<String, dynamic> payload,
    @JsonKey(
      name: 'command_status',
      fromJson: CommandStatus.fromWire,
      toJson: CommandStatus.toWire,
    )
    CommandStatus commandStatus,
    @JsonKey(name: 'claim_token') String? claimToken,
    @JsonKey(name: 'claimed_at') DateTime? claimedAt,
    @JsonKey(name: 'attempt_count') int attemptCount,
    @JsonKey(name: 'finished_at') DateTime? finishedAt,
  });
}

/// @nodoc
class _$CommandCopyWithImpl<$Res, $Val extends Command>
    implements $CommandCopyWith<$Res> {
  _$CommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commandId = null,
    Object? commandGameId = freezed,
    Object? commandCreatedAt = null,
    Object? playerId = freezed,
    Object? commandType = null,
    Object? payload = null,
    Object? commandStatus = null,
    Object? claimToken = freezed,
    Object? claimedAt = freezed,
    Object? attemptCount = null,
    Object? finishedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            commandId: null == commandId
                ? _value.commandId
                : commandId // ignore: cast_nullable_to_non_nullable
                      as String,
            commandGameId: freezed == commandGameId
                ? _value.commandGameId
                : commandGameId // ignore: cast_nullable_to_non_nullable
                      as String?,
            commandCreatedAt: null == commandCreatedAt
                ? _value.commandCreatedAt
                : commandCreatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            playerId: freezed == playerId
                ? _value.playerId
                : playerId // ignore: cast_nullable_to_non_nullable
                      as String?,
            commandType: null == commandType
                ? _value.commandType
                : commandType // ignore: cast_nullable_to_non_nullable
                      as CommandType,
            payload: null == payload
                ? _value.payload
                : payload // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            commandStatus: null == commandStatus
                ? _value.commandStatus
                : commandStatus // ignore: cast_nullable_to_non_nullable
                      as CommandStatus,
            claimToken: freezed == claimToken
                ? _value.claimToken
                : claimToken // ignore: cast_nullable_to_non_nullable
                      as String?,
            claimedAt: freezed == claimedAt
                ? _value.claimedAt
                : claimedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            attemptCount: null == attemptCount
                ? _value.attemptCount
                : attemptCount // ignore: cast_nullable_to_non_nullable
                      as int,
            finishedAt: freezed == finishedAt
                ? _value.finishedAt
                : finishedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommandImplCopyWith<$Res> implements $CommandCopyWith<$Res> {
  factory _$$CommandImplCopyWith(
    _$CommandImpl value,
    $Res Function(_$CommandImpl) then,
  ) = __$$CommandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'command_id') String commandId,
    @JsonKey(name: 'command_game_id') String? commandGameId,
    @JsonKey(name: 'command_created_at') DateTime commandCreatedAt,
    @JsonKey(name: 'player_id') String? playerId,
    @JsonKey(
      name: 'command_type',
      fromJson: CommandType.fromWire,
      toJson: CommandType.toWire,
    )
    CommandType commandType,
    @JsonKey(name: 'payload') Map<String, dynamic> payload,
    @JsonKey(
      name: 'command_status',
      fromJson: CommandStatus.fromWire,
      toJson: CommandStatus.toWire,
    )
    CommandStatus commandStatus,
    @JsonKey(name: 'claim_token') String? claimToken,
    @JsonKey(name: 'claimed_at') DateTime? claimedAt,
    @JsonKey(name: 'attempt_count') int attemptCount,
    @JsonKey(name: 'finished_at') DateTime? finishedAt,
  });
}

/// @nodoc
class __$$CommandImplCopyWithImpl<$Res>
    extends _$CommandCopyWithImpl<$Res, _$CommandImpl>
    implements _$$CommandImplCopyWith<$Res> {
  __$$CommandImplCopyWithImpl(
    _$CommandImpl _value,
    $Res Function(_$CommandImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? commandId = null,
    Object? commandGameId = freezed,
    Object? commandCreatedAt = null,
    Object? playerId = freezed,
    Object? commandType = null,
    Object? payload = null,
    Object? commandStatus = null,
    Object? claimToken = freezed,
    Object? claimedAt = freezed,
    Object? attemptCount = null,
    Object? finishedAt = freezed,
  }) {
    return _then(
      _$CommandImpl(
        commandId: null == commandId
            ? _value.commandId
            : commandId // ignore: cast_nullable_to_non_nullable
                  as String,
        commandGameId: freezed == commandGameId
            ? _value.commandGameId
            : commandGameId // ignore: cast_nullable_to_non_nullable
                  as String?,
        commandCreatedAt: null == commandCreatedAt
            ? _value.commandCreatedAt
            : commandCreatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        playerId: freezed == playerId
            ? _value.playerId
            : playerId // ignore: cast_nullable_to_non_nullable
                  as String?,
        commandType: null == commandType
            ? _value.commandType
            : commandType // ignore: cast_nullable_to_non_nullable
                  as CommandType,
        payload: null == payload
            ? _value._payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        commandStatus: null == commandStatus
            ? _value.commandStatus
            : commandStatus // ignore: cast_nullable_to_non_nullable
                  as CommandStatus,
        claimToken: freezed == claimToken
            ? _value.claimToken
            : claimToken // ignore: cast_nullable_to_non_nullable
                  as String?,
        claimedAt: freezed == claimedAt
            ? _value.claimedAt
            : claimedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        attemptCount: null == attemptCount
            ? _value.attemptCount
            : attemptCount // ignore: cast_nullable_to_non_nullable
                  as int,
        finishedAt: freezed == finishedAt
            ? _value.finishedAt
            : finishedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommandImpl implements _Command {
  const _$CommandImpl({
    @JsonKey(name: 'command_id') required this.commandId,
    @JsonKey(name: 'command_game_id') this.commandGameId,
    @JsonKey(name: 'command_created_at') required this.commandCreatedAt,
    @JsonKey(name: 'player_id') this.playerId,
    @JsonKey(
      name: 'command_type',
      fromJson: CommandType.fromWire,
      toJson: CommandType.toWire,
    )
    required this.commandType,
    @JsonKey(name: 'payload') required final Map<String, dynamic> payload,
    @JsonKey(
      name: 'command_status',
      fromJson: CommandStatus.fromWire,
      toJson: CommandStatus.toWire,
    )
    required this.commandStatus,
    @JsonKey(name: 'claim_token') this.claimToken,
    @JsonKey(name: 'claimed_at') this.claimedAt,
    @JsonKey(name: 'attempt_count') required this.attemptCount,
    @JsonKey(name: 'finished_at') this.finishedAt,
  }) : _payload = payload;

  factory _$CommandImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommandImplFromJson(json);

  @override
  @JsonKey(name: 'command_id')
  final String commandId;
  @override
  @JsonKey(name: 'command_game_id')
  final String? commandGameId;
  @override
  @JsonKey(name: 'command_created_at')
  final DateTime commandCreatedAt;
  @override
  @JsonKey(name: 'player_id')
  final String? playerId;
  @override
  @JsonKey(
    name: 'command_type',
    fromJson: CommandType.fromWire,
    toJson: CommandType.toWire,
  )
  final CommandType commandType;
  final Map<String, dynamic> _payload;
  @override
  @JsonKey(name: 'payload')
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  @JsonKey(
    name: 'command_status',
    fromJson: CommandStatus.fromWire,
    toJson: CommandStatus.toWire,
  )
  final CommandStatus commandStatus;
  @override
  @JsonKey(name: 'claim_token')
  final String? claimToken;
  @override
  @JsonKey(name: 'claimed_at')
  final DateTime? claimedAt;
  @override
  @JsonKey(name: 'attempt_count')
  final int attemptCount;
  @override
  @JsonKey(name: 'finished_at')
  final DateTime? finishedAt;

  @override
  String toString() {
    return 'Command(commandId: $commandId, commandGameId: $commandGameId, commandCreatedAt: $commandCreatedAt, playerId: $playerId, commandType: $commandType, payload: $payload, commandStatus: $commandStatus, claimToken: $claimToken, claimedAt: $claimedAt, attemptCount: $attemptCount, finishedAt: $finishedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommandImpl &&
            (identical(other.commandId, commandId) ||
                other.commandId == commandId) &&
            (identical(other.commandGameId, commandGameId) ||
                other.commandGameId == commandGameId) &&
            (identical(other.commandCreatedAt, commandCreatedAt) ||
                other.commandCreatedAt == commandCreatedAt) &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.commandType, commandType) ||
                other.commandType == commandType) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.commandStatus, commandStatus) ||
                other.commandStatus == commandStatus) &&
            (identical(other.claimToken, claimToken) ||
                other.claimToken == claimToken) &&
            (identical(other.claimedAt, claimedAt) ||
                other.claimedAt == claimedAt) &&
            (identical(other.attemptCount, attemptCount) ||
                other.attemptCount == attemptCount) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    commandId,
    commandGameId,
    commandCreatedAt,
    playerId,
    commandType,
    const DeepCollectionEquality().hash(_payload),
    commandStatus,
    claimToken,
    claimedAt,
    attemptCount,
    finishedAt,
  );

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommandImplCopyWith<_$CommandImpl> get copyWith =>
      __$$CommandImplCopyWithImpl<_$CommandImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommandImplToJson(this);
  }
}

abstract class _Command implements Command {
  const factory _Command({
    @JsonKey(name: 'command_id') required final String commandId,
    @JsonKey(name: 'command_game_id') final String? commandGameId,
    @JsonKey(name: 'command_created_at')
    required final DateTime commandCreatedAt,
    @JsonKey(name: 'player_id') final String? playerId,
    @JsonKey(
      name: 'command_type',
      fromJson: CommandType.fromWire,
      toJson: CommandType.toWire,
    )
    required final CommandType commandType,
    @JsonKey(name: 'payload') required final Map<String, dynamic> payload,
    @JsonKey(
      name: 'command_status',
      fromJson: CommandStatus.fromWire,
      toJson: CommandStatus.toWire,
    )
    required final CommandStatus commandStatus,
    @JsonKey(name: 'claim_token') final String? claimToken,
    @JsonKey(name: 'claimed_at') final DateTime? claimedAt,
    @JsonKey(name: 'attempt_count') required final int attemptCount,
    @JsonKey(name: 'finished_at') final DateTime? finishedAt,
  }) = _$CommandImpl;

  factory _Command.fromJson(Map<String, dynamic> json) = _$CommandImpl.fromJson;

  @override
  @JsonKey(name: 'command_id')
  String get commandId;
  @override
  @JsonKey(name: 'command_game_id')
  String? get commandGameId;
  @override
  @JsonKey(name: 'command_created_at')
  DateTime get commandCreatedAt;
  @override
  @JsonKey(name: 'player_id')
  String? get playerId;
  @override
  @JsonKey(
    name: 'command_type',
    fromJson: CommandType.fromWire,
    toJson: CommandType.toWire,
  )
  CommandType get commandType;
  @override
  @JsonKey(name: 'payload')
  Map<String, dynamic> get payload;
  @override
  @JsonKey(
    name: 'command_status',
    fromJson: CommandStatus.fromWire,
    toJson: CommandStatus.toWire,
  )
  CommandStatus get commandStatus;
  @override
  @JsonKey(name: 'claim_token')
  String? get claimToken;
  @override
  @JsonKey(name: 'claimed_at')
  DateTime? get claimedAt;
  @override
  @JsonKey(name: 'attempt_count')
  int get attemptCount;
  @override
  @JsonKey(name: 'finished_at')
  DateTime? get finishedAt;

  /// Create a copy of Command
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommandImplCopyWith<_$CommandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
