import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/core/trading/personal_order.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/orders/pending_orders_view_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/neon_button.dart';

void main() {
  final t0 = DateTime.utc(2018, 7, 10, 12, 0);

  const List<TradingOrderTargetGame> eligibleGamesAbTest = [
    TradingOrderTargetGame(
      gameId: 'g-test',
      gameTitle: 'Game A',
      gameDescription: '',
    ),
    TradingOrderTargetGame(
      gameId: 'g-test',
      gameTitle: 'Game B',
      gameDescription: '',
    ),
  ];

  const List<TradingOrderTargetGame> eligibleGamesOlderLaterTest = [
    TradingOrderTargetGame(
      gameId: 'g-test',
      gameTitle: 'Game Older',
      gameDescription: '',
    ),
    TradingOrderTargetGame(
      gameId: 'g-test',
      gameTitle: 'Game Later',
      gameDescription: '',
    ),
  ];

  const List<TradingOrderTargetGame> eligibleForexTest = [
    TradingOrderTargetGame(
      gameId: 'g-forex',
      gameTitle: 'Forex Masters',
      gameDescription: '',
    ),
  ];

  const List<TradingOrderTargetGame> eligibleSingleGTest = [
    TradingOrderTargetGame(
      gameId: 'g-test',
      gameTitle: 'G',
      gameDescription: '',
    ),
  ];

  List<PendingOrderListItem> twoGamesTwoSides() => [
        PendingOrderListItem(
          gameId: 'g-test',
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
          gameId: 'g-test',
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

  List<PendingOrderListItem> multiRowSameGame() => [
        PendingOrderListItem(
          gameId: 'g-test',
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
          gameId: 'g-test',
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
          gameId: 'g-test',
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
  List<PendingOrderListItem> twoCreatedAtOlderFirst(DateTime earlier) => [
        PendingOrderListItem(
          gameId: 'g-test',
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
          gameId: 'g-test',
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
          items: twoGamesTwoSides(),
          tradingGamesForNewOrder: eligibleGamesAbTest,
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
    expect(find.text('(Select All)'), findsOneWidget);
  });

  testWidgets('newest createdAt renders above older regardless of source order',
      (tester) async {
    final pair = twoCreatedAtOlderFirst(t0);
    for (final items in [pair, pair.reversed.toList()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: PendingOrdersScreen(
            items: items,
            tradingGamesForNewOrder: eligibleGamesOlderLaterTest,
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
          items: twoGamesTwoSides(),
          tradingGamesForNewOrder: eligibleGamesAbTest,
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
          items: multiRowSameGame(),
          tradingGamesForNewOrder: eligibleGamesAbTest,
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
            items: multiRowSameGame(),
            tradingGamesForNewOrder: eligibleGamesAbTest,
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
            items: twoGamesTwoSides(),
            tradingGamesForNewOrder: eligibleGamesAbTest,
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
            items: twoGamesTwoSides(),
            tradingGamesForNewOrder: eligibleGamesAbTest,
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
          items: twoGamesTwoSides(),
          tradingGamesForNewOrder: eligibleGamesAbTest,
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

  testWidgets(
    'partial-cancel modal pending line updates when items refresh (live qty)',
    (tester) async {
    final harnessKey = GlobalKey<PendingOrdersLivePendingHarnessState>();
    await tester.pumpWidget(
      PendingOrdersLivePendingHarness(
        key: harnessKey,
        eligibleGames: eligibleSingleGTest,
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pending-order-card-live-qty')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('pending-order-cancel-live-qty')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('You have 10 pending units of this order left.'),
      findsOneWidget,
    );

    harnessKey.currentState!.setOrderQuantityCurrent(7);
    await tester.pump();
    await tester.pump();

    expect(
      find.text('You have 7 pending units of this order left.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('partial-cancel-close')));
    await tester.pumpAndSettle();
  });

  testWidgets('onCancelOrder invoked after partial-cancel modal submit',
      (tester) async {
    final cancelled = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          tradingGamesForNewOrder: eligibleSingleGTest,
          items: [
            PendingOrderListItem(
              gameId: 'g-test',
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
          onCancelOrder: (row, qty) async {
            cancelled.add('${row.order.id}:$qty');
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('pending-order-card-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-order-cancel-c1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('partial-cancel-submit')));
    await tester.pumpAndSettle();

    expect(cancelled, ['c1:3']);
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
          home: PendingOrdersScreen(),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('pending-orders-scaffold')), findsOneWidget);
      expect(find.text('Forex Masters'), findsOneWidget);
      expect(find.text('Crypto Sim 2024'), findsOneWidget);
    },
  );

  testWidgets(
    'pending orders title is slightly emphasized; Filter stays muted',
    (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: const [],
        ),
      ),
    );
    await tester.pump();
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('pending-orders-title')),
    );
    expect(title.style?.fontSize, 14);
    expect(title.style?.color, AppColors.textSecondary);

    final filterText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('pending-orders-filter-btn')),
        matching: find.text('Filter'),
      ),
    );
    expect(filterText.style?.fontSize, 12);
    expect(filterText.style?.color, AppColors.textTertiary);
  });

  testWidgets('create new order is disabled when there are no eligible trading games',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: const [],
          tradingGamesForNewOrder: const [],
        ),
      ),
    );
    await tester.pump();
    final btn = tester.widget<NeonButton>(
      find.byKey(const ValueKey('pending-orders-create-new-order')),
    );
    expect(btn.onPressed, isNull);
  });

  testWidgets('create new order opens modal and prepends pending-xg row',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          items: twoGamesTwoSides(),
          tradingGamesForNewOrder: eligibleGamesAbTest,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('pending-orders-create-new-order')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('new-order-dialog')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-order-game')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-order-bid-ask-mid')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('new-order-submit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-order-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pending-order-card-pending-xg-1')), findsOneWidget);
    expect(find.textContaining('Game A'), findsWidgets);

    final newRowTop = tester.getTopLeft(
      find.byKey(const ValueKey('pending-order-card-pending-xg-1')),
    ).dy;
    final olderTop = tester.getTopLeft(
      find.byKey(const ValueKey('pending-order-card-buy-1')),
    ).dy;
    expect(newRowTop, lessThan(olderTop));
  });

  testWidgets(
      'create new order shows numeric bid–ask midpoint for mocked book title',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PendingOrdersScreen(
          tradingGamesForNewOrder: eligibleForexTest,
          items: [
            PendingOrderListItem(
              gameId: 'g-forex',
              gameTitle: 'Forex Masters',
              gameDescription: '',
              order: PersonalOrder(
                id: 'fx-1',
                side: PersonalOrderSide.buy,
                orderType: PersonalOrderType.limit,
                quantityInitial: 1,
                quantityCurrent: 1,
                limitPrice: 150,
                status: PersonalOrderStatus.resting,
                createdAt: t0,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('pending-orders-create-new-order')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bid Ask Midpoint \$150.00'), findsOneWidget);
  });
}

/// Drives [PendingOrdersScreen] with mutable [items] so tests can simulate a
/// parent refresh (e.g. silent poll) while the partial-cancel modal is open.
class PendingOrdersLivePendingHarness extends StatefulWidget {
  const PendingOrdersLivePendingHarness({
    super.key,
    required this.eligibleGames,
  });

  final List<TradingOrderTargetGame> eligibleGames;

  @override
  PendingOrdersLivePendingHarnessState createState() =>
      PendingOrdersLivePendingHarnessState();
}

class PendingOrdersLivePendingHarnessState
    extends State<PendingOrdersLivePendingHarness> {
  static final _t0 = DateTime.utc(2018, 7, 10, 12, 0);

  late List<PendingOrderListItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      PendingOrderListItem(
        gameId: 'g-test',
        gameTitle: 'G',
        gameDescription: '',
        order: PersonalOrder(
          id: 'live-qty',
          side: PersonalOrderSide.buy,
          orderType: PersonalOrderType.limit,
          quantityInitial: 10,
          quantityCurrent: 10,
          limitPrice: 99,
          status: PersonalOrderStatus.resting,
          createdAt: _t0,
        ),
      ),
    ];
  }

  /// Simulates the shell passing a new [PendingOrdersScreen.items] snapshot.
  void setOrderQuantityCurrent(int quantityCurrent) {
    setState(() {
      _items = [
        _items[0].copyWith(
          order: _items[0].order.copyWith(quantityCurrent: quantityCurrent),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildAppTheme(),
      home: PendingOrdersScreen(
        items: _items,
        tradingGamesForNewOrder: widget.eligibleGames,
        onCancelOrder: (_, __) async {},
      ),
    );
  }
}
