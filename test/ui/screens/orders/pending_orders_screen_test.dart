import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 3, 12, 0);

  List<PendingOrderListItem> _twoGamesTwoSides() => [
        PendingOrderListItem(
          gameTitle: 'Game A',
          gameDescription: '',
          order: PersonalOrder(
            id: 'buy-1',
            side: PersonalOrderSide.buy,
            orderType: PersonalOrderType.limit,
            quantityInitial: 1,
            quantityCurrent: 1,
            limitPrice: 1,
            status: PersonalOrderStatus.resting,
            createdAt: t0,
          ),
        ),
        PendingOrderListItem(
          gameTitle: 'Game B',
          gameDescription: '',
          order: PersonalOrder(
            id: 'sell-1',
            side: PersonalOrderSide.sell,
            orderType: PersonalOrderType.limit,
            quantityInitial: 2,
            quantityCurrent: 2,
            limitPrice: 2,
            status: PersonalOrderStatus.resting,
            createdAt: t0.add(const Duration(minutes: 1)),
          ),
        ),
      ];

  List<PendingOrderListItem> _multiRowSameGame() => [
        PendingOrderListItem(
          gameTitle: 'Game A',
          gameDescription: '',
          order: PersonalOrder(
            id: 'a-buy',
            side: PersonalOrderSide.buy,
            orderType: PersonalOrderType.limit,
            quantityInitial: 1,
            quantityCurrent: 1,
            limitPrice: 1,
            status: PersonalOrderStatus.resting,
            createdAt: t0,
          ),
        ),
        PendingOrderListItem(
          gameTitle: 'Game A',
          gameDescription: '',
          order: PersonalOrder(
            id: 'a-sell',
            side: PersonalOrderSide.sell,
            orderType: PersonalOrderType.limit,
            quantityInitial: 1,
            quantityCurrent: 1,
            limitPrice: 2,
            status: PersonalOrderStatus.resting,
            createdAt: t0,
          ),
        ),
        PendingOrderListItem(
          gameTitle: 'Game B',
          gameDescription: '',
          order: PersonalOrder(
            id: 'b-buy',
            side: PersonalOrderSide.buy,
            orderType: PersonalOrderType.limit,
            quantityInitial: 1,
            quantityCurrent: 1,
            limitPrice: 3,
            status: PersonalOrderStatus.resting,
            createdAt: t0,
          ),
        ),
      ];

  /// Source list ordered **oldest first** (`older` then `later`); `later` has
  /// the newer `createdAt` so the screen should show it **above** `older`.
  List<PendingOrderListItem> _twoCreatedAtOlderFirst(DateTime earlier) => [
        PendingOrderListItem(
          gameTitle: 'Game Older',
          gameDescription: '',
          order: PersonalOrder(
            id: 'older',
            side: PersonalOrderSide.buy,
            orderType: PersonalOrderType.limit,
            quantityInitial: 1,
            quantityCurrent: 1,
            limitPrice: 1,
            status: PersonalOrderStatus.resting,
            createdAt: earlier,
          ),
        ),
        PendingOrderListItem(
          gameTitle: 'Game Later',
          gameDescription: '',
          order: PersonalOrder(
            id: 'later',
            side: PersonalOrderSide.sell,
            orderType: PersonalOrderType.limit,
            quantityInitial: 2,
            quantityCurrent: 2,
            limitPrice: 2,
            status: PersonalOrderStatus.resting,
            createdAt: earlier.add(const Duration(hours: 1)),
          ),
        ),
      ];

  Future<void> tapApply(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey('pending-orders-filter-apply')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('filter sheet lists direction and game checkboxes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: _twoGamesTwoSides(),
          now: () => t0,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pending-orders-filter-dir-buy')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-filter-dir-sell')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-filter-game-Game_A')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-filter-game-Game_B')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-filter-apply')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-filter-reset')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-orders-filter-games-select-all')), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);
  });

  testWidgets('newest createdAt renders above older regardless of source order',
      (tester) async {
    final pair = _twoCreatedAtOlderFirst(t0);
    for (final items in [pair, pair.reversed.toList()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(
            items: items,
            now: () => t0,
          ),
        ),
      );
      await tester.pump();

      final olderFinder = find.byKey(
        const ValueKey('pending-order-card-older'),
      );
      final laterFinder = find.byKey(
        const ValueKey('pending-order-card-later'),
      );

      expect(olderFinder, findsOneWidget);
      expect(laterFinder, findsOneWidget);

      final laterTop = tester.getTopLeft(laterFinder).dy;
      final olderTop = tester.getTopLeft(olderFinder).dy;
      expect(laterTop, lessThan(olderTop));
    }
  });

  testWidgets('apply buy-only hides sell card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: _twoGamesTwoSides(),
          now: () => t0,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('pending-order-card-buy-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-dir-buy')));
    await tester.pumpAndSettle();
    await tapApply(tester);

    expect(find.byKey(const ValueKey('pending-order-card-buy-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsNothing);
  });

  testWidgets('game multi-select narrows to chosen titles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: _multiRowSameGame(),
          now: () => t0,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('pending-order-card-a-buy')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-a-sell')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-b-buy')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pending-orders-filter-game-Game_A')),
    );
    await tester.pumpAndSettle();
    await tapApply(tester);

    expect(find.byKey(const ValueKey('pending-order-card-a-buy')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-a-sell')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-b-buy')), findsNothing);
  });

  testWidgets(
    'games select all selects every title then apply shows all game rows',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(
            items: _multiRowSameGame(),
            now: () => t0,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('pending-orders-filter-game-Game_A')),
      );
      await tester.pumpAndSettle();
      await tapApply(tester);
      expect(
        find.byKey(const ValueKey('pending-order-card-b-buy')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('pending-orders-filter-games-select-all')),
      );
      await tester.pumpAndSettle();
      await tapApply(tester);

      expect(find.byKey(const ValueKey('pending-order-card-a-buy')), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-order-card-b-buy')), findsOneWidget);
    },
  );

  testWidgets(
    'all directions unchecked still shows buys and sells after apply',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(
            items: _twoGamesTwoSides(),
            now: () => t0,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
      await tester.pumpAndSettle();
      await tapApply(tester);

      expect(find.byKey(const ValueKey('pending-order-card-buy-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsOneWidget);
    },
  );

  testWidgets(
    'uncheck buy after buy-only filter restores sell rows',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(
            items: _twoGamesTwoSides(),
            now: () => t0,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-dir-buy')));
      await tester.pumpAndSettle();
      await tapApply(tester);
      expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pending-orders-filter-dir-buy')));
      await tester.pumpAndSettle();
      await tapApply(tester);

      expect(find.byKey(const ValueKey('pending-order-card-buy-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsOneWidget);
    },
  );

  testWidgets('reset restores both cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: _twoGamesTwoSides(),
          now: () => t0,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-dir-buy')));
    await tester.pumpAndSettle();
    await tapApply(tester);
    expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-orders-filter-reset')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pending-order-card-buy-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending-order-card-sell-1')), findsOneWidget);
  });

  testWidgets('empty source shows zero message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: const [],
          now: () => t0,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('pending-orders-empty-msg-zero')),
      findsOneWidget,
    );
    expect(find.text('No pending orders'), findsOneWidget);
  });

  testWidgets('onCancelOrder invoked after nested dialog confirm',
      (tester) async {
    final cancelled = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: [
            PendingOrderListItem(
              gameTitle: 'G',
              gameDescription: '',
              order: PersonalOrder(
                id: 'c1',
                side: PersonalOrderSide.buy,
                orderType: PersonalOrderType.limit,
                quantityInitial: 3,
                quantityCurrent: 3,
                limitPrice: 99,
                status: PersonalOrderStatus.resting,
                createdAt: t0,
              ),
            ),
          ],
          now: () => t0,
          onCancelOrder: cancelled.add,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pending-order-card-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-order-cancel-c1')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Cancel'),
      ),
    );
    await tester.pumpAndSettle();

    expect(cancelled, ['c1']);
  });

  testWidgets(
    'default mock list renders multiple cards without explicit items',
    (tester) async {
      tester.view.physicalSize = const Size(480, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(now: () => DateTime.utc(2026, 5, 3, 15, 0)),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('pending-orders-scaffold')), findsOneWidget);
      expect(find.text('Forex Masters'), findsOneWidget);
      expect(find.text('Crypto Sim 2024'), findsOneWidget);
    },
  );

  testWidgets(
    'pending orders header row typography matches section muted style',
    (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: const [],
          now: () => t0,
        ),
      ),
    );
    await tester.pump();
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('pending-orders-title')),
    );
    expect(title.style?.fontSize, 12);
    expect(title.style?.color, AppColors.textTertiary);

    final filterText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('pending-orders-filter-btn')),
        matching: find.text('Filter'),
      ),
    );
    expect(filterText.style?.fontSize, 12);
    expect(filterText.style?.color, AppColors.textTertiary);
  });
}
