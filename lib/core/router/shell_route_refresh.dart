import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/view_data/home_view_data_provider.dart';
import '../../providers/view_data/pending_orders_view_data_provider.dart';
import 'app_router.dart';

/// Refreshes shell-tab view data when navigation lands on home or orders.
///
/// Called from [appRouterProvider] on every route transition so refreshes
/// run regardless of entry path (back button, bottom nav, deep link, etc.).
void refreshShellTabDataForRoute(
  String matchedLocation, {
  required T Function<T>(ProviderListenable<T> provider) read,
}) {
  switch (matchedLocation) {
    case AppRoutes.home:
      read(homeViewDataProvider.notifier).silentRefresh();
    case AppRoutes.orders:
      read(pendingOrdersViewDataProvider.notifier).silentRefresh();
    default:
      break;
  }
}
