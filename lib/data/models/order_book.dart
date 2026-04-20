import 'package:collection/collection.dart';

/// A single level in a one-sided order book: all resting quantity at a
/// given price, aggregated across players.
class OrderBookLevel {
  const OrderBookLevel({
    required this.price,
    required this.totalQuantity,
  });

  final double price;
  final int totalQuantity;

  @override
  bool operator ==(Object other) =>
      other is OrderBookLevel &&
      other.price == price &&
      other.totalQuantity == totalQuantity;

  @override
  int get hashCode => Object.hash(price, totalQuantity);

  @override
  String toString() =>
      'OrderBookLevel(price: $price, qty: $totalQuantity)';
}

/// Both sides of the book. `bids` is sorted descending by price (best
/// bid first), `asks` ascending (best ask first).
class OrderBook {
  OrderBook({
    required List<OrderBookLevel> bids,
    required List<OrderBookLevel> asks,
  })  : bids = List.unmodifiable(bids),
        asks = List.unmodifiable(asks);

  final List<OrderBookLevel> bids;
  final List<OrderBookLevel> asks;

  bool get isEmpty => bids.isEmpty && asks.isEmpty;

  /// Best bid (highest price). Null if no bids exist.
  OrderBookLevel? get bestBid => bids.firstOrNull;

  /// Best ask (lowest price). Null if no asks exist.
  OrderBookLevel? get bestAsk => asks.firstOrNull;

  @override
  bool operator ==(Object other) =>
      other is OrderBook &&
      const ListEquality<OrderBookLevel>().equals(other.bids, bids) &&
      const ListEquality<OrderBookLevel>().equals(other.asks, asks);

  @override
  int get hashCode => Object.hash(
        const ListEquality<OrderBookLevel>().hash(bids),
        const ListEquality<OrderBookLevel>().hash(asks),
      );

  @override
  String toString() =>
      'OrderBook(bids: ${bids.length}, asks: ${asks.length})';
}
