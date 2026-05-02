import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/ui/screens/trading/trading_stat_format.dart';
import 'package:uncertain_envelopes_2/ui/widgets/game_result_player_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows three stats and initials', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GameResultPlayerCard(
          displayName: 'AdminUser',
          avatarInitials: 'AD',
          deltaCash: 500,
          deltaEnvelopes: -2,
          pnl: 210,
        ),
      ),
    );
    expect(find.text('DELTA CASH'), findsOneWidget);
    expect(find.text('DELTA ENV'), findsOneWidget);
    expect(find.text('PNL'), findsOneWidget);
    expect(find.text('+\$500'), findsOneWidget);
    expect(find.text('-2'), findsOneWidget);
    expect(find.text('+\$210'), findsOneWidget);
    expect(find.text('AD'), findsOneWidget);
  });

  testWidgets('negative PNL uses secondary color', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GameResultPlayerCard(
          displayName: 'X',
          avatarInitials: 'X',
          deltaCash: 0,
          deltaEnvelopes: 0,
          pnl: -50,
        ),
      ),
    );
    final pnlText = tester.widget<Text>(find.text(r'-$50'));
    expect(pnlText.style?.color, AppColors.secondary);
  });

  testWidgets('zero PNL uses neutral color', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GameResultPlayerCard(
          displayName: 'X',
          avatarInitials: 'X',
          deltaCash: 1,
          deltaEnvelopes: 1,
          pnl: 0,
        ),
      ),
    );
    final pnlText = tester.widget<Text>(find.text(r'$0'));
    expect(pnlText.style?.color, AppColors.textTertiary);
  });

  testWidgets('empty initials fall back to ?', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GameResultPlayerCard(
          displayName: 'Y',
          avatarInitials: '   ',
          deltaCash: 0,
          deltaEnvelopes: 0,
          pnl: 0,
        ),
      ),
    );
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('null PnL shows placeholder dash', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GameResultPlayerCard(
          displayName: 'Y',
          avatarInitials: 'Y',
          deltaCash: 0,
          deltaEnvelopes: 0,
          pnl: null,
        ),
      ),
    );
    final pnlCell = find.descendant(
      of: find.byType(GameResultPlayerCard),
      matching: find.text(kUnsetUsdLine),
    );
    expect(pnlCell, findsOneWidget);
    final pnlText = tester.widget<Text>(pnlCell);
    expect(pnlText.style?.color, AppColors.textTertiary);
  });
}
