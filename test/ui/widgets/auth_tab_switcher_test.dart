import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_colors.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/auth_tab_switcher.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
}

void main() {
  group('AuthTabSwitcher rendering', () {
    testWidgets('renders both tab labels in uppercase', (tester) async {
      await _pump(
        tester,
        AuthTabSwitcher(selected: AuthTab.logIn, onChanged: (_) {}),
      );
      expect(find.text('LOG IN'), findsOneWidget);
      expect(find.text('SIGN UP'), findsOneWidget);
    });

    testWidgets('both tabs share the bar row', (tester) async {
      await _pump(
        tester,
        AuthTabSwitcher(selected: AuthTab.logIn, onChanged: (_) {}),
      );
      expect(find.byType(AuthTabSwitcher), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(2));
    });
  });

  group('AuthTabSwitcher active styling', () {
    Color _textColor(WidgetTester tester, String label) {
      final text = tester.widget<Text>(find.text(label));
      return text.style!.color!;
    }

    testWidgets('LogIn selected: LOG IN is primary, SIGN UP is tertiary',
        (tester) async {
      await _pump(
        tester,
        AuthTabSwitcher(selected: AuthTab.logIn, onChanged: (_) {}),
      );
      expect(_textColor(tester, 'LOG IN'), AppColors.primary);
      expect(_textColor(tester, 'SIGN UP'), AppColors.textTertiary);
    });

    testWidgets('SignUp selected: SIGN UP is primary, LOG IN is tertiary',
        (tester) async {
      await _pump(
        tester,
        AuthTabSwitcher(selected: AuthTab.signUp, onChanged: (_) {}),
      );
      expect(_textColor(tester, 'SIGN UP'), AppColors.primary);
      expect(_textColor(tester, 'LOG IN'), AppColors.textTertiary);
    });
  });

  group('AuthTabSwitcher interaction', () {
    testWidgets('tapping LOG IN fires onChanged(logIn)', (tester) async {
      AuthTab? last;
      await _pump(
        tester,
        AuthTabSwitcher(
          selected: AuthTab.signUp,
          onChanged: (t) => last = t,
        ),
      );
      await tester.tap(find.text('LOG IN'));
      await tester.pump();
      expect(last, AuthTab.logIn);
    });

    testWidgets('tapping SIGN UP fires onChanged(signUp)', (tester) async {
      AuthTab? last;
      await _pump(
        tester,
        AuthTabSwitcher(
          selected: AuthTab.logIn,
          onChanged: (t) => last = t,
        ),
      );
      await tester.tap(find.text('SIGN UP'));
      await tester.pump();
      expect(last, AuthTab.signUp);
    });

    testWidgets('tapping the currently-selected tab still fires onChanged',
        (tester) async {
      final seen = <AuthTab>[];
      await _pump(
        tester,
        AuthTabSwitcher(
          selected: AuthTab.logIn,
          onChanged: seen.add,
        ),
      );
      await tester.tap(find.text('LOG IN'));
      await tester.pump();
      // The switcher is stateless — it always reports the tap; parent
      // decides whether it's a no-op. This confirms no swallowing.
      expect(seen, [AuthTab.logIn]);
    });

    testWidgets('rapid taps each fire independently', (tester) async {
      final seen = <AuthTab>[];
      await _pump(
        tester,
        AuthTabSwitcher(
          selected: AuthTab.logIn,
          onChanged: seen.add,
        ),
      );
      await tester.tap(find.text('SIGN UP'));
      await tester.pump();
      await tester.tap(find.text('LOG IN'));
      await tester.pump();
      await tester.tap(find.text('SIGN UP'));
      await tester.pump();
      expect(seen, [AuthTab.signUp, AuthTab.logIn, AuthTab.signUp]);
    });
  });

  group('AuthTabSwitcher edge cases', () {
    testWidgets('renders at very narrow 240px without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(240, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await _pump(
        tester,
        AuthTabSwitcher(selected: AuthTab.logIn, onChanged: (_) {}),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
