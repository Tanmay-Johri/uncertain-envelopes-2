import '../../data/enums/order_status.dart';
import '../../data/models/order.dart';
import 'personal_order.dart';

/// Maps a backend [Order] row into the trading UI’s [PersonalOrder] model.
PersonalOrder personalOrderFromOrder(Order o) {
  final side = o.type.isBuy ? PersonalOrderSide.buy : PersonalOrderSide.sell;
  final orderType =
      o.type.isLimit ? PersonalOrderType.limit : PersonalOrderType.market;
  return PersonalOrder(
    id: o.orderId,
    side: side,
    orderType: orderType,
    quantityInitial: o.quantityInitial,
    quantityCurrent: o.quantityCurrent,
    limitPrice: o.pricePerStock,
    status: personalOrderStatusFromOrderStatus(o.status),
    createdAt: o.orderCreatedAt,
  );
}

PersonalOrderStatus personalOrderStatusFromOrderStatus(OrderStatus s) {
  return switch (s) {
    OrderStatus.inQueue => PersonalOrderStatus.inQueue,
    OrderStatus.beingProcessed => PersonalOrderStatus.beingProcessed,
    OrderStatus.orderResting => PersonalOrderStatus.resting,
    OrderStatus.orderClosed => PersonalOrderStatus.filled,
    OrderStatus.cancelled => PersonalOrderStatus.cancelled,
    OrderStatus.gameEnded => PersonalOrderStatus.gameEnded,
  };
}
