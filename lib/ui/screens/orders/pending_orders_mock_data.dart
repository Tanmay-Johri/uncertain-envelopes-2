import '../../../core/trading/personal_order.dart';
import 'pending_orders_view_data.dart';

/// Sample rows only: fixed UTC instants in the **past** so any order with
/// [DateTime.now].toUtc always sorts **above** these under
/// [pendingOrderListItemsSortedNewestFirst].
final _sampleRowsBaseUtc = DateTime.utc(2018, 6, 1, 14, 0);

/// Default mock list aligned with
/// `design-uncertain-envelopes-2/admin_game_trading_dashboard_4/code.html`.
List<PendingOrderListItem> kMockPendingOrders() => pendingOrderListItemsSortedNewestFirst([
      PendingOrderListItem(
        gameTitle: 'Forex Masters',
        gameDescription:
            'High-liquidity currency pairs. Spreads are tight during London open.',
        order: PersonalOrder(
          id: 'ord-forex-1',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 10,
          quantityCurrent: 10,
          limitPrice: 150,
          status: PersonalOrderStatus.resting,
          createdAt: _sampleRowsBaseUtc.add(const Duration(minutes: 5)),
        ),
      ),
      PendingOrderListItem(
        gameTitle: 'Crypto Sim 2024',
        gameDescription:
            'Beginner level currency trading simulation. Market volatility is currently high.',
        order: PersonalOrder(
          id: '88293-A',
          side: PersonalOrderSide.sell,
          orderType: PersonalOrderType.limit,
          quantityInitial: 500,
          quantityCurrent: 500,
          limitPrice: 0.45,
          status: PersonalOrderStatus.resting,
          createdAt: _sampleRowsBaseUtc.add(const Duration(minutes: 2)),
        ),
      ),
      PendingOrderListItem(
        gameTitle: 'Commodity Tycoon',
        gameDescription:
            'Futures-style envelope contracts on imaginary commodities.',
        order: PersonalOrder(
          id: 'ord-com-ty',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 5,
          quantityCurrent: 5,
          limitPrice: 1200,
          status: PersonalOrderStatus.inQueue,
          createdAt: _sampleRowsBaseUtc.add(const Duration(seconds: 30)),
        ),
      ),
      PendingOrderListItem(
        gameTitle: 'Start-up Equity',
        gameDescription: 'Angel rounds and dilution as a trading metaphor.',
        order: PersonalOrder(
          id: 'ord-su-25',
          side: PersonalOrderSide.sell,
          orderType: PersonalOrderType.limit,
          quantityInitial: 25,
          quantityCurrent: 25,
          limitPrice: 42.50,
          status: PersonalOrderStatus.beingProcessed,
          createdAt: _sampleRowsBaseUtc,
        ),
      ),
    ]);
