import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/router/shell_route_refresh.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/providers/view_data/pending_orders_view_data_provider.dart';

import '../../support/home_view_data_fakes.dart';
import '../../support/pending_orders_view_data_fakes.dart';

void main() {
  group('refreshShellTabDataForRoute', () {
    test('home route triggers home silentRefresh', () async {
      final home = HomeViewDataSilentRefreshSpy();
      final orders = PendingOrdersViewDataSilentRefreshSpy();
      final container = ProviderContainer(
        overrides: [
          homeViewDataProvider.overrideWith(() => home),
          pendingOrdersViewDataProvider.overrideWith(() => orders),
        ],
      );
      addTearDown(container.dispose);

      refreshShellTabDataForRoute(AppRoutes.home, read: container.read);
      await Future<void>.delayed(Duration.zero);

      expect(home.refreshCount, 1);
      expect(orders.refreshCount, 0);
    });

    test('orders route triggers pending orders silentRefresh', () async {
      final home = HomeViewDataSilentRefreshSpy();
      final orders = PendingOrdersViewDataSilentRefreshSpy();
      final container = ProviderContainer(
        overrides: [
          homeViewDataProvider.overrideWith(() => home),
          pendingOrdersViewDataProvider.overrideWith(() => orders),
        ],
      );
      addTearDown(container.dispose);

      refreshShellTabDataForRoute(AppRoutes.orders, read: container.read);
      await Future<void>.delayed(Duration.zero);

      expect(home.refreshCount, 0);
      expect(orders.refreshCount, 1);
    });

    test('other routes do not refresh shell tab data', () async {
      final home = HomeViewDataSilentRefreshSpy();
      final orders = PendingOrdersViewDataSilentRefreshSpy();
      final container = ProviderContainer(
        overrides: [
          homeViewDataProvider.overrideWith(() => home),
          pendingOrdersViewDataProvider.overrideWith(() => orders),
        ],
      );
      addTearDown(container.dispose);

      refreshShellTabDataForRoute(AppRoutes.create, read: container.read);
      refreshShellTabDataForRoute(AppRoutes.gameLobby('g1'), read: container.read);
      await Future<void>.delayed(Duration.zero);

      expect(home.refreshCount, 0);
      expect(orders.refreshCount, 0);
    });
  });
}
