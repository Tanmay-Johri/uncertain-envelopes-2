import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/login_form.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<LoginSubmission> onSubmit,
  VoidCallback? onForgot,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LoginForm(onSubmit: onSubmit, onForgotTap: onForgot),
        ),
      ),
    ),
  );
}

Future<void> _enter(
  WidgetTester tester,
  Key key,
  String text,
) async {
  await tester.enterText(find.byKey(key), text);
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

void main() {
  group('LoginForm rendering', () {
    testWidgets('renders identifier + password fields and submit button',
        (tester) async {
      await _pump(tester, onSubmit: (_) {});
      expect(find.text('USERNAME OR EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.byKey(const Key('login_identifier_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('password field is obscured by default', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      final finder = find.descendant(
        of: find.byKey(const Key('login_password_field')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(finder).obscureText, isTrue);
    });

    testWidgets('password visibility toggle obscures and reveals text',
        (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _enter(tester, const Key('login_password_field'), 'secret');
      final field = find.descendant(
        of: find.byKey(const Key('login_password_field')),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(field).obscureText, isTrue);

      await tester.tap(
        find.byKey(const ValueKey('login_password_visibility_toggle')),
      );
      await tester.pump();
      expect(tester.widget<TextField>(field).obscureText, isFalse);

      await tester.tap(
        find.byKey(const ValueKey('login_password_visibility_toggle')),
      );
      await tester.pump();
      expect(tester.widget<TextField>(field).obscureText, isTrue);
    });

    testWidgets('renders the Forgot? link', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      expect(find.text('FORGOT?'), findsOneWidget);
    });
  });

  group('LoginForm validation', () {
    testWidgets('empty fields → both show Required, onSubmit not called',
        (tester) async {
      var called = 0;
      await _pump(tester, onSubmit: (_) => called++);
      await _tapSubmit(tester);
      expect(find.text('Required'), findsNWidgets(2));
      expect(called, 0);
    });

    testWidgets('only identifier filled → password shows Required',
        (tester) async {
      var called = 0;
      await _pump(tester, onSubmit: (_) => called++);
      await _enter(tester, const Key('login_identifier_field'), 'tanmay');
      await _tapSubmit(tester);
      expect(find.text('Required'), findsOneWidget);
      expect(called, 0);
    });

    testWidgets('only password filled → identifier shows Required',
        (tester) async {
      var called = 0;
      await _pump(tester, onSubmit: (_) => called++);
      await _enter(tester, const Key('login_password_field'), 'hunter2');
      await _tapSubmit(tester);
      expect(find.text('Required'), findsOneWidget);
      expect(called, 0);
    });

    testWidgets('whitespace-only identifier is treated as empty',
        (tester) async {
      var called = 0;
      await _pump(tester, onSubmit: (_) => called++);
      await _enter(tester, const Key('login_identifier_field'), '   ');
      await _enter(tester, const Key('login_password_field'), 'hunter2');
      await _tapSubmit(tester);
      expect(find.text('Required'), findsOneWidget);
      expect(called, 0);
    });

    testWidgets('errors appear only after first submit, not on first render',
        (tester) async {
      await _pump(tester, onSubmit: (_) {});
      expect(find.text('Required'), findsNothing);
    });

    testWidgets('errors clear in real time once fields become valid',
        (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _tapSubmit(tester);
      expect(find.text('Required'), findsNWidgets(2));

      await _enter(tester, const Key('login_identifier_field'), 'tanmay');
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      await _enter(tester, const Key('login_password_field'), 'hunter2');
      await tester.pump();
      expect(find.text('Required'), findsNothing);
    });
  });

  group('LoginForm submission', () {
    testWidgets('valid data trims identifier and passes both values',
        (tester) async {
      LoginSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _enter(tester, const Key('login_identifier_field'), '  tanmay  ');
      await _enter(tester, const Key('login_password_field'), ' hunter2 ');
      await _tapSubmit(tester);
      expect(captured, isNotNull);
      expect(captured!.identifier, 'tanmay');
      // Password itself is NOT trimmed — a trailing space in a password
      // is a legitimate character.
      expect(captured!.password, ' hunter2 ');
    });

    testWidgets('pressing Enter in the password field submits',
        (tester) async {
      LoginSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _enter(tester, const Key('login_identifier_field'), 'tanmay');
      await _enter(tester, const Key('login_password_field'), 'hunter2');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.identifier, 'tanmay');
    });

    testWidgets('three rapid submit taps fire exactly three callbacks',
        (tester) async {
      var calls = 0;
      await _pump(tester, onSubmit: (_) => calls++);
      await _enter(tester, const Key('login_identifier_field'), 'tanmay');
      await _enter(tester, const Key('login_password_field'), 'hunter2');
      await _tapSubmit(tester);
      await _tapSubmit(tester);
      await _tapSubmit(tester);
      expect(calls, 3);
    });
  });

  group('LoginForm Forgot?', () {
    testWidgets('tapping FORGOT? fires onForgotTap', (tester) async {
      var tapped = 0;
      await _pump(tester, onSubmit: (_) {}, onForgot: () => tapped++);
      await tester.tap(find.text('FORGOT?'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('missing onForgotTap does not crash on tap', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await tester.tap(find.text('FORGOT?'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
