/// Lifecycle status of an order. See PRD §orders.status.
enum OrderStatus {
  inQueue('in_queue'),
  beingProcessed('being_processed'),
  orderResting('order_resting'),
  orderClosed('order_closed'),
  cancelled('cancelled'),
  gameEnded('game_ended');

  const OrderStatus(this.wireValue);

  final String wireValue;

  /// Terminal means the order will never transition again.
  bool get isTerminal =>
      this == OrderStatus.orderClosed ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.gameEnded;

  bool get isActive => !isTerminal;

  static OrderStatus fromWire(String value) {
    for (final s in OrderStatus.values) {
      if (s.wireValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'Unknown OrderStatus');
  }

  static OrderStatus? tryFromWire(String? value) {
    if (value == null) return null;
    for (final s in OrderStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}
