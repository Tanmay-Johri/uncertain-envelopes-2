import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/app_shell.dart';
import 'package:uncertain_envelopes_2/ui/widgets/uncertain_envelopes_logo_mark.dart';

Future<void> _pumpShell(
  WidgetTester tester, {
  required int currentIndex,
  ValueChanged<int>? onTap,
  VoidCallback? onAccount,
  Widget? body,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: AppShell(
        currentIndex: currentIndex,
        onDestinationSelected: onTap ?? (_) {},
        onAccountTap: onAccount ?? () {},
        child: body ?? const Text('BODY'),
      ),
    ),
  );
}

void main() {
  group('AppShell', () {
    testWidgets('renders the brand header mark', (tester) async {
      await _pumpShell(tester, currentIndex: 0);
      expect(
        find.bySemanticsLabel(
          UncertainEnvelopesLogoMark.kUncertainEnvelopesBrandSemanticsLabel,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the body child', (tester) async {
      await _pumpShell(
        tester,
        currentIndex: 0,
        body: const Text('HELLO BODY'),
      );
      expect(find.text('HELLO BODY'), findsOneWidget);
    });

    testWidgets('renders exactly three bottom nav items', (tester) async {
      await _pumpShell(tester, currentIndex: 0);
      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.items.length, 3);
      expect(bar.items[0].label, 'HOME');
      expect(bar.items[1].label, 'CREATE');
      expect(bar.items[2].label, 'ORDERS');
    });

    testWidgets('currentIndex is forwarded to the bottom nav',
        (tester) async {
      await _pumpShell(tester, currentIndex: 2);
      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, 2);
    });

    testWidgets('tapping a nav item fires onDestinationSelected',
        (tester) async {
      int? tapped;
      await _pumpShell(
        tester,
        currentIndex: 0,
        onTap: (i) => tapped = i,
      );
      await tester.tap(find.text('CREATE'));
      await tester.pump();
      expect(tapped, 1);

      await tester.tap(find.text('ORDERS'));
      await tester.pump();
      expect(tapped, 2);

      await tester.tap(find.text('HOME'));
      await tester.pump();
      expect(tapped, 0);
    });

    testWidgets('tapping the account icon fires onAccountTap',
        (tester) async {
      var accountTaps = 0;
      await _pumpShell(
        tester,
        currentIndex: 0,
        onAccount: () => accountTaps++,
      );
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pump();
      expect(accountTaps, 1);
    });

    testWidgets('rapid tab taps each fire independently', (tester) async {
      final taps = <int>[];
      await _pumpShell(
        tester,
        currentIndex: 0,
        onTap: taps.add,
      );
      await tester.tap(find.text('CREATE'));
      await tester.pump();
      await tester.tap(find.text('CREATE'));
      await tester.pump();
      await tester.tap(find.text('CREATE'));
      expect(taps, [1, 1, 1]);
    });

    testWidgets('rebuilds when currentIndex changes', (tester) async {
      await _pumpShell(tester, currentIndex: 0);
      var bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, 0);

      await _pumpShell(tester, currentIndex: 2);
      bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, 2);
    });

    testWidgets('renders in very narrow widths without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(240, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpShell(tester, currentIndex: 0);
      expect(tester.takeException(), isNull);
    });
  });
}
