/// Side + execution kind of an order. The PRD stores a single combined
/// `type` column rather than separate side/execution_type columns.
enum OrderType {
  limitBuy('limit_buy'),
  limitSell('limit_sell'),
  marketBuy('market_buy'),
  marketSell('market_sell');

  const OrderType(this.wireValue);

  final String wireValue;

  bool get isBuy =>
      this == OrderType.limitBuy || this == OrderType.marketBuy;
  bool get isSell =>
      this == OrderType.limitSell || this == OrderType.marketSell;
  bool get isLimit =>
      this == OrderType.limitBuy || this == OrderType.limitSell;
  bool get isMarket =>
      this == OrderType.marketBuy || this == OrderType.marketSell;

  static String toWire(OrderType value) => value.wireValue;

  static OrderType fromWire(String value) {
    for (final t in OrderType.values) {
      if (t.wireValue == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'Unknown OrderType');
  }

  static OrderType? tryFromWire(String? value) {
    if (value == null) return null;
    for (final t in OrderType.values) {
      if (t.wireValue == value) return t;
    }
    return null;
  }
}
