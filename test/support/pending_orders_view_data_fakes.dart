import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/providers/view_data/pending_orders_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';

/// Counts [silentRefresh] invocations for route-refresh tests.
class PendingOrdersViewDataSilentRefreshSpy extends PendingOrdersViewData {
  var refreshCount = 0;

  @override
  Future<PendingOrdersScreenData> build() async =>
      const PendingOrdersScreenData(items: [], tradingGamesForNewOrder: []);

  @override
  Future<void> silentRefresh() async {
    refreshCount++;
    state = const AsyncValue.data(
      PendingOrdersScreenData(items: [], tradingGamesForNewOrder: []),
    );
  }
}
