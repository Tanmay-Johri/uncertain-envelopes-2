// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'execution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Execution _$ExecutionFromJson(Map<String, dynamic> json) {
  return _Execution.fromJson(json);
}

/// @nodoc
mixin _$Execution {
  @JsonKey(name: 'executions_id')
  String get executionsId => throw _privateConstructorUsedError;
  @JsonKey(name: 'executions_game_id')
  String get executionsGameId => throw _privateConstructorUsedError;
  @JsonKey(name: 'buy_order_id')
  String get buyOrderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sell_order_id')
  String get sellOrderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity')
  int get quantity => throw _privateConstructorUsedError;
  @JsonKey(name: 'execution_price')
  double get executionPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'executed_at')
  DateTime get executedAt => throw _privateConstructorUsedError;

  /// Serializes this Execution to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Execution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExecutionCopyWith<Execution> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExecutionCopyWith<$Res> {
  factory $ExecutionCopyWith(Execution value, $Res Function(Execution) then) =
      _$ExecutionCopyWithImpl<$Res, Execution>;
  @useResult
  $Res call({
    @JsonKey(name: 'executions_id') String executionsId,
    @JsonKey(name: 'executions_game_id') String executionsGameId,
    @JsonKey(name: 'buy_order_id') String buyOrderId,
    @JsonKey(name: 'sell_order_id') String sellOrderId,
    @JsonKey(name: 'quantity') int quantity,
    @JsonKey(name: 'execution_price') double executionPrice,
    @JsonKey(name: 'executed_at') DateTime executedAt,
  });
}

/// @nodoc
class _$ExecutionCopyWithImpl<$Res, $Val extends Execution>
    implements $ExecutionCopyWith<$Res> {
  _$ExecutionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Execution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? executionsId = null,
    Object? executionsGameId = null,
    Object? buyOrderId = null,
    Object? sellOrderId = null,
    Object? quantity = null,
    Object? executionPrice = null,
    Object? executedAt = null,
  }) {
    return _then(
      _value.copyWith(
            executionsId: null == executionsId
                ? _value.executionsId
                : executionsId // ignore: cast_nullable_to_non_nullable
                      as String,
            executionsGameId: null == executionsGameId
                ? _value.executionsGameId
                : executionsGameId // ignore: cast_nullable_to_non_nullable
                      as String,
            buyOrderId: null == buyOrderId
                ? _value.buyOrderId
                : buyOrderId // ignore: cast_nullable_to_non_nullable
                      as String,
            sellOrderId: null == sellOrderId
                ? _value.sellOrderId
                : sellOrderId // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as int,
            executionPrice: null == executionPrice
                ? _value.executionPrice
                : executionPrice // ignore: cast_nullable_to_non_nullable
                      as double,
            executedAt: null == executedAt
                ? _value.executedAt
                : executedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExecutionImplCopyWith<$Res>
    implements $ExecutionCopyWith<$Res> {
  factory _$$ExecutionImplCopyWith(
    _$ExecutionImpl value,
    $Res Function(_$ExecutionImpl) then,
  ) = __$$ExecutionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'executions_id') String executionsId,
    @JsonKey(name: 'executions_game_id') String executionsGameId,
    @JsonKey(name: 'buy_order_id') String buyOrderId,
    @JsonKey(name: 'sell_order_id') String sellOrderId,
    @JsonKey(name: 'quantity') int quantity,
    @JsonKey(name: 'execution_price') double executionPrice,
    @JsonKey(name: 'executed_at') DateTime executedAt,
  });
}

/// @nodoc
class __$$ExecutionImplCopyWithImpl<$Res>
    extends _$ExecutionCopyWithImpl<$Res, _$ExecutionImpl>
    implements _$$ExecutionImplCopyWith<$Res> {
  __$$ExecutionImplCopyWithImpl(
    _$ExecutionImpl _value,
    $Res Function(_$ExecutionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Execution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? executionsId = null,
    Object? executionsGameId = null,
    Object? buyOrderId = null,
    Object? sellOrderId = null,
    Object? quantity = null,
    Object? executionPrice = null,
    Object? executedAt = null,
  }) {
    return _then(
      _$ExecutionImpl(
        executionsId: null == executionsId
            ? _value.executionsId
            : executionsId // ignore: cast_nullable_to_non_nullable
                  as String,
        executionsGameId: null == executionsGameId
            ? _value.executionsGameId
            : executionsGameId // ignore: cast_nullable_to_non_nullable
                  as String,
        buyOrderId: null == buyOrderId
            ? _value.buyOrderId
            : buyOrderId // ignore: cast_nullable_to_non_nullable
                  as String,
        sellOrderId: null == sellOrderId
            ? _value.sellOrderId
            : sellOrderId // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        executionPrice: null == executionPrice
            ? _value.executionPrice
            : executionPrice // ignore: cast_nullable_to_non_nullable
                  as double,
        executedAt: null == executedAt
            ? _value.executedAt
            : executedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExecutionImpl implements _Execution {
  const _$ExecutionImpl({
    @JsonKey(name: 'executions_id') required this.executionsId,
    @JsonKey(name: 'executions_game_id') required this.executionsGameId,
    @JsonKey(name: 'buy_order_id') required this.buyOrderId,
    @JsonKey(name: 'sell_order_id') required this.sellOrderId,
    @JsonKey(name: 'quantity') required this.quantity,
    @JsonKey(name: 'execution_price') required this.executionPrice,
    @JsonKey(name: 'executed_at') required this.executedAt,
  });

  factory _$ExecutionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExecutionImplFromJson(json);

  @override
  @JsonKey(name: 'executions_id')
  final String executionsId;
  @override
  @JsonKey(name: 'executions_game_id')
  final String executionsGameId;
  @override
  @JsonKey(name: 'buy_order_id')
  final String buyOrderId;
  @override
  @JsonKey(name: 'sell_order_id')
  final String sellOrderId;
  @override
  @JsonKey(name: 'quantity')
  final int quantity;
  @override
  @JsonKey(name: 'execution_price')
  final double executionPrice;
  @override
  @JsonKey(name: 'executed_at')
  final DateTime executedAt;

  @override
  String toString() {
    return 'Execution(executionsId: $executionsId, executionsGameId: $executionsGameId, buyOrderId: $buyOrderId, sellOrderId: $sellOrderId, quantity: $quantity, executionPrice: $executionPrice, executedAt: $executedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExecutionImpl &&
            (identical(other.executionsId, executionsId) ||
                other.executionsId == executionsId) &&
            (identical(other.executionsGameId, executionsGameId) ||
                other.executionsGameId == executionsGameId) &&
            (identical(other.buyOrderId, buyOrderId) ||
                other.buyOrderId == buyOrderId) &&
            (identical(other.sellOrderId, sellOrderId) ||
                other.sellOrderId == sellOrderId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.executionPrice, executionPrice) ||
                other.executionPrice == executionPrice) &&
            (identical(other.executedAt, executedAt) ||
                other.executedAt == executedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    executionsId,
    executionsGameId,
    buyOrderId,
    sellOrderId,
    quantity,
    executionPrice,
    executedAt,
  );

  /// Create a copy of Execution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExecutionImplCopyWith<_$ExecutionImpl> get copyWith =>
      __$$ExecutionImplCopyWithImpl<_$ExecutionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExecutionImplToJson(this);
  }
}

abstract class _Execution implements Execution {
  const factory _Execution({
    @JsonKey(name: 'executions_id') required final String executionsId,
    @JsonKey(name: 'executions_game_id') required final String executionsGameId,
    @JsonKey(name: 'buy_order_id') required final String buyOrderId,
    @JsonKey(name: 'sell_order_id') required final String sellOrderId,
    @JsonKey(name: 'quantity') required final int quantity,
    @JsonKey(name: 'execution_price') required final double executionPrice,
    @JsonKey(name: 'executed_at') required final DateTime executedAt,
  }) = _$ExecutionImpl;

  factory _Execution.fromJson(Map<String, dynamic> json) =
      _$ExecutionImpl.fromJson;

  @override
  @JsonKey(name: 'executions_id')
  String get executionsId;
  @override
  @JsonKey(name: 'executions_game_id')
  String get executionsGameId;
  @override
  @JsonKey(name: 'buy_order_id')
  String get buyOrderId;
  @override
  @JsonKey(name: 'sell_order_id')
  String get sellOrderId;
  @override
  @JsonKey(name: 'quantity')
  int get quantity;
  @override
  @JsonKey(name: 'execution_price')
  double get executionPrice;
  @override
  @JsonKey(name: 'executed_at')
  DateTime get executedAt;

  /// Create a copy of Execution
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExecutionImplCopyWith<_$ExecutionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
