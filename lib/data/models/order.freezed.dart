// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Order _$OrderFromJson(Map<String, dynamic> json) {
  return _Order.fromJson(json);
}

/// @nodoc
mixin _$Order {
  @JsonKey(name: 'order_id')
  String get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by_player_id')
  String get createdByPlayerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_id')
  String get gameId => throw _privateConstructorUsedError;
  @JsonKey(name: 'type', fromJson: OrderType.fromWire, toJson: OrderType.toWire)
  OrderType get type => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_initial')
  int get quantityInitial => throw _privateConstructorUsedError;
  @JsonKey(name: 'quantity_current')
  int get quantityCurrent => throw _privateConstructorUsedError;
  @JsonKey(name: 'price_per_stock')
  double? get pricePerStock => throw _privateConstructorUsedError;
  @JsonKey(
    name: 'status',
    fromJson: OrderStatus.fromWire,
    toJson: OrderStatus.toWire,
  )
  OrderStatus get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_created_at')
  DateTime get orderCreatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_updated_at')
  DateTime get orderUpdatedAt => throw _privateConstructorUsedError;

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCopyWith<Order> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) then) =
      _$OrderCopyWithImpl<$Res, Order>;
  @useResult
  $Res call({
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'created_by_player_id') String createdByPlayerId,
    @JsonKey(name: 'game_id') String gameId,
    @JsonKey(
      name: 'type',
      fromJson: OrderType.fromWire,
      toJson: OrderType.toWire,
    )
    OrderType type,
    @JsonKey(name: 'quantity_initial') int quantityInitial,
    @JsonKey(name: 'quantity_current') int quantityCurrent,
    @JsonKey(name: 'price_per_stock') double? pricePerStock,
    @JsonKey(
      name: 'status',
      fromJson: OrderStatus.fromWire,
      toJson: OrderStatus.toWire,
    )
    OrderStatus status,
    @JsonKey(name: 'order_created_at') DateTime orderCreatedAt,
    @JsonKey(name: 'order_updated_at') DateTime orderUpdatedAt,
  });
}

/// @nodoc
class _$OrderCopyWithImpl<$Res, $Val extends Order>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? createdByPlayerId = null,
    Object? gameId = null,
    Object? type = null,
    Object? quantityInitial = null,
    Object? quantityCurrent = null,
    Object? pricePerStock = freezed,
    Object? status = null,
    Object? orderCreatedAt = null,
    Object? orderUpdatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            orderId: null == orderId
                ? _value.orderId
                : orderId // ignore: cast_nullable_to_non_nullable
                      as String,
            createdByPlayerId: null == createdByPlayerId
                ? _value.createdByPlayerId
                : createdByPlayerId // ignore: cast_nullable_to_non_nullable
                      as String,
            gameId: null == gameId
                ? _value.gameId
                : gameId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as OrderType,
            quantityInitial: null == quantityInitial
                ? _value.quantityInitial
                : quantityInitial // ignore: cast_nullable_to_non_nullable
                      as int,
            quantityCurrent: null == quantityCurrent
                ? _value.quantityCurrent
                : quantityCurrent // ignore: cast_nullable_to_non_nullable
                      as int,
            pricePerStock: freezed == pricePerStock
                ? _value.pricePerStock
                : pricePerStock // ignore: cast_nullable_to_non_nullable
                      as double?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as OrderStatus,
            orderCreatedAt: null == orderCreatedAt
                ? _value.orderCreatedAt
                : orderCreatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            orderUpdatedAt: null == orderUpdatedAt
                ? _value.orderUpdatedAt
                : orderUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrderImplCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$$OrderImplCopyWith(
    _$OrderImpl value,
    $Res Function(_$OrderImpl) then,
  ) = __$$OrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'order_id') String orderId,
    @JsonKey(name: 'created_by_player_id') String createdByPlayerId,
    @JsonKey(name: 'game_id') String gameId,
    @JsonKey(
      name: 'type',
      fromJson: OrderType.fromWire,
      toJson: OrderType.toWire,
    )
    OrderType type,
    @JsonKey(name: 'quantity_initial') int quantityInitial,
    @JsonKey(name: 'quantity_current') int quantityCurrent,
    @JsonKey(name: 'price_per_stock') double? pricePerStock,
    @JsonKey(
      name: 'status',
      fromJson: OrderStatus.fromWire,
      toJson: OrderStatus.toWire,
    )
    OrderStatus status,
    @JsonKey(name: 'order_created_at') DateTime orderCreatedAt,
    @JsonKey(name: 'order_updated_at') DateTime orderUpdatedAt,
  });
}

/// @nodoc
class __$$OrderImplCopyWithImpl<$Res>
    extends _$OrderCopyWithImpl<$Res, _$OrderImpl>
    implements _$$OrderImplCopyWith<$Res> {
  __$$OrderImplCopyWithImpl(
    _$OrderImpl _value,
    $Res Function(_$OrderImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = null,
    Object? createdByPlayerId = null,
    Object? gameId = null,
    Object? type = null,
    Object? quantityInitial = null,
    Object? quantityCurrent = null,
    Object? pricePerStock = freezed,
    Object? status = null,
    Object? orderCreatedAt = null,
    Object? orderUpdatedAt = null,
  }) {
    return _then(
      _$OrderImpl(
        orderId: null == orderId
            ? _value.orderId
            : orderId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdByPlayerId: null == createdByPlayerId
            ? _value.createdByPlayerId
            : createdByPlayerId // ignore: cast_nullable_to_non_nullable
                  as String,
        gameId: null == gameId
            ? _value.gameId
            : gameId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as OrderType,
        quantityInitial: null == quantityInitial
            ? _value.quantityInitial
            : quantityInitial // ignore: cast_nullable_to_non_nullable
                  as int,
        quantityCurrent: null == quantityCurrent
            ? _value.quantityCurrent
            : quantityCurrent // ignore: cast_nullable_to_non_nullable
                  as int,
        pricePerStock: freezed == pricePerStock
            ? _value.pricePerStock
            : pricePerStock // ignore: cast_nullable_to_non_nullable
                  as double?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as OrderStatus,
        orderCreatedAt: null == orderCreatedAt
            ? _value.orderCreatedAt
            : orderCreatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        orderUpdatedAt: null == orderUpdatedAt
            ? _value.orderUpdatedAt
            : orderUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderImpl implements _Order {
  const _$OrderImpl({
    @JsonKey(name: 'order_id') required this.orderId,
    @JsonKey(name: 'created_by_player_id') required this.createdByPlayerId,
    @JsonKey(name: 'game_id') required this.gameId,
    @JsonKey(
      name: 'type',
      fromJson: OrderType.fromWire,
      toJson: OrderType.toWire,
    )
    required this.type,
    @JsonKey(name: 'quantity_initial') required this.quantityInitial,
    @JsonKey(name: 'quantity_current') required this.quantityCurrent,
    @JsonKey(name: 'price_per_stock') this.pricePerStock,
    @JsonKey(
      name: 'status',
      fromJson: OrderStatus.fromWire,
      toJson: OrderStatus.toWire,
    )
    required this.status,
    @JsonKey(name: 'order_created_at') required this.orderCreatedAt,
    @JsonKey(name: 'order_updated_at') required this.orderUpdatedAt,
  });

  factory _$OrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderImplFromJson(json);

  @override
  @JsonKey(name: 'order_id')
  final String orderId;
  @override
  @JsonKey(name: 'created_by_player_id')
  final String createdByPlayerId;
  @override
  @JsonKey(name: 'game_id')
  final String gameId;
  @override
  @JsonKey(name: 'type', fromJson: OrderType.fromWire, toJson: OrderType.toWire)
  final OrderType type;
  @override
  @JsonKey(name: 'quantity_initial')
  final int quantityInitial;
  @override
  @JsonKey(name: 'quantity_current')
  final int quantityCurrent;
  @override
  @JsonKey(name: 'price_per_stock')
  final double? pricePerStock;
  @override
  @JsonKey(
    name: 'status',
    fromJson: OrderStatus.fromWire,
    toJson: OrderStatus.toWire,
  )
  final OrderStatus status;
  @override
  @JsonKey(name: 'order_created_at')
  final DateTime orderCreatedAt;
  @override
  @JsonKey(name: 'order_updated_at')
  final DateTime orderUpdatedAt;

  @override
  String toString() {
    return 'Order(orderId: $orderId, createdByPlayerId: $createdByPlayerId, gameId: $gameId, type: $type, quantityInitial: $quantityInitial, quantityCurrent: $quantityCurrent, pricePerStock: $pricePerStock, status: $status, orderCreatedAt: $orderCreatedAt, orderUpdatedAt: $orderUpdatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.createdByPlayerId, createdByPlayerId) ||
                other.createdByPlayerId == createdByPlayerId) &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.quantityInitial, quantityInitial) ||
                other.quantityInitial == quantityInitial) &&
            (identical(other.quantityCurrent, quantityCurrent) ||
                other.quantityCurrent == quantityCurrent) &&
            (identical(other.pricePerStock, pricePerStock) ||
                other.pricePerStock == pricePerStock) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.orderCreatedAt, orderCreatedAt) ||
                other.orderCreatedAt == orderCreatedAt) &&
            (identical(other.orderUpdatedAt, orderUpdatedAt) ||
                other.orderUpdatedAt == orderUpdatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    orderId,
    createdByPlayerId,
    gameId,
    type,
    quantityInitial,
    quantityCurrent,
    pricePerStock,
    status,
    orderCreatedAt,
    orderUpdatedAt,
  );

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      __$$OrderImplCopyWithImpl<_$OrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderImplToJson(this);
  }
}

abstract class _Order implements Order {
  const factory _Order({
    @JsonKey(name: 'order_id') required final String orderId,
    @JsonKey(name: 'created_by_player_id')
    required final String createdByPlayerId,
    @JsonKey(name: 'game_id') required final String gameId,
    @JsonKey(
      name: 'type',
      fromJson: OrderType.fromWire,
      toJson: OrderType.toWire,
    )
    required final OrderType type,
    @JsonKey(name: 'quantity_initial') required final int quantityInitial,
    @JsonKey(name: 'quantity_current') required final int quantityCurrent,
    @JsonKey(name: 'price_per_stock') final double? pricePerStock,
    @JsonKey(
      name: 'status',
      fromJson: OrderStatus.fromWire,
      toJson: OrderStatus.toWire,
    )
    required final OrderStatus status,
    @JsonKey(name: 'order_created_at') required final DateTime orderCreatedAt,
    @JsonKey(name: 'order_updated_at') required final DateTime orderUpdatedAt,
  }) = _$OrderImpl;

  factory _Order.fromJson(Map<String, dynamic> json) = _$OrderImpl.fromJson;

  @override
  @JsonKey(name: 'order_id')
  String get orderId;
  @override
  @JsonKey(name: 'created_by_player_id')
  String get createdByPlayerId;
  @override
  @JsonKey(name: 'game_id')
  String get gameId;
  @override
  @JsonKey(name: 'type', fromJson: OrderType.fromWire, toJson: OrderType.toWire)
  OrderType get type;
  @override
  @JsonKey(name: 'quantity_initial')
  int get quantityInitial;
  @override
  @JsonKey(name: 'quantity_current')
  int get quantityCurrent;
  @override
  @JsonKey(name: 'price_per_stock')
  double? get pricePerStock;
  @override
  @JsonKey(
    name: 'status',
    fromJson: OrderStatus.fromWire,
    toJson: OrderStatus.toWire,
  )
  OrderStatus get status;
  @override
  @JsonKey(name: 'order_created_at')
  DateTime get orderCreatedAt;
  @override
  @JsonKey(name: 'order_updated_at')
  DateTime get orderUpdatedAt;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
