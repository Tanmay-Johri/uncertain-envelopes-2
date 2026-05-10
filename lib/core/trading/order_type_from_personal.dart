import '../../data/enums/order_type.dart';
import 'personal_order.dart';

OrderType orderTypeFromPersonalDraft(PersonalOrder o) {
  return switch ((o.side, o.orderType)) {
    (PersonalOrderSide.buy, PersonalOrderType.limit) => OrderType.limitBuy,
    (PersonalOrderSide.buy, PersonalOrderType.market) => OrderType.marketBuy,
    (PersonalOrderSide.sell, PersonalOrderType.limit) => OrderType.limitSell,
    (PersonalOrderSide.sell, PersonalOrderType.market) => OrderType.marketSell,
  };
}
