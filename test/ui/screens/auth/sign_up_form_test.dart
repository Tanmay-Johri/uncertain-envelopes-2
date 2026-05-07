import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/constants/app_constants.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/sign_up_form.dart';

const _usernameKey = Key('signup_username_field');
const _emailKey = Key('signup_email_field');
const _passwordKey = Key('signup_password_field');
const _submitKey = Key('signup_submit_button');

Future<void> _pump(
  WidgetTester tester, {
  required ValueChanged<SignUpSubmission> onSubmit,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: SignUpForm(onSubmit: onSubmit),
          ),
        ),
      ),
    ),
  );
}

Future<void> _enter(WidgetTester t, Key k, String s) async {
  await t.enterText(find.byKey(k), s);
}

Future<void> _tapSubmit(WidgetTester t) async {
  await t.tap(find.byKey(_submitKey));
  await t.pumpAndSettle();
}

Future<void> _fillValid(
  WidgetTester t, {
  String username = 'tanmay',
  String email = 'trader@example.com',
  String password = 'hunter2x',
}) async {
  await _enter(t, _usernameKey, username);
  await _enter(t, _emailKey, email);
  await _enter(t, _passwordKey, password);
}

void main() {
  group('SignUpForm rendering', () {
    testWidgets('renders all three fields and the submit button',
        (tester) async {
      await _pump(tester, onSubmit: (_) {});
      expect(find.text('USERNAME'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.byKey(_usernameKey), findsOneWidget);
      expect(find.byKey(_emailKey), findsOneWidget);
      expect(find.byKey(_passwordKey), findsOneWidget);
      expect(find.byKey(_submitKey), findsOneWidget);
    });

    testWidgets('password field is obscured', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      final tf = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(_passwordKey),
          matching: find.byType(TextField),
        ),
      );
      expect(tf.obscureText, isTrue);
    });

    testWidgets('no validation errors on first render', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      expect(find.text('Required'), findsNothing);
    });
  });

  group('SignUpForm required-field validation', () {
    testWidgets('empty submit → all three fields show Required',
        (tester) async {
      var called = 0;
      await _pump(tester, onSubmit: (_) => called++);
      await _tapSubmit(tester);
      expect(find.text('Required'), findsNWidgets(3));
      expect(called, 0);
    });

    testWidgets('whitespace-only username is Required', (tester) async {
      var called = 0;
      await _pump(tester, onSubmit: (_) => called++);
      await _fillValid(tester, username: '   ');
      await _tapSubmit(tester);
      expect(find.text('Required'), findsOneWidget);
      expect(called, 0);
    });
  });

  group('SignUpForm username validation', () {
    testWidgets('<3 chars shows length error', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, username: 'ab');
      await _tapSubmit(tester);
      expect(
        find.text('At least ${AppConstants.minUsernameLength} characters'),
        findsOneWidget,
      );
    });

    testWidgets('>32 chars shows length error', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, username: 'a' * 33);
      await _tapSubmit(tester);
      expect(
        find.text('At most ${AppConstants.maxUsernameLength} characters'),
        findsOneWidget,
      );
    });

    testWidgets('invalid characters (spaces, @, !) show charset error',
        (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, username: 'bad name!');
      await _tapSubmit(tester);
      expect(find.text('Letters, numbers, _ or - only'), findsOneWidget);
    });

    testWidgets('boundary: exactly 3 chars is valid', (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _fillValid(tester, username: 'abc');
      await _tapSubmit(tester);
      expect(captured, isNotNull);
      expect(captured!.username, 'abc');
    });

    testWidgets('boundary: exactly 32 chars is valid', (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      final u = 'a' * 32;
      await _fillValid(tester, username: u);
      await _tapSubmit(tester);
      expect(captured, isNotNull);
      expect(captured!.username.length, 32);
    });

    testWidgets('underscore, hyphen, digits all allowed', (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _fillValid(tester, username: 'tan_may-42');
      await _tapSubmit(tester);
      expect(captured, isNotNull);
      expect(captured!.username, 'tan_may-42');
    });

    testWidgets('username is normalized to lowercase on submit',
        (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _fillValid(tester, username: 'TanMay');
      await _tapSubmit(tester);
      expect(captured, isNotNull);
      expect(captured!.username, 'tanmay');
    });
  });

  group('SignUpForm email validation', () {
    testWidgets('missing @ shows Invalid email', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, email: 'bademail');
      await _tapSubmit(tester);
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('multiple @ shows Invalid email', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, email: 'a@b@c.com');
      await _tapSubmit(tester);
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('missing domain TLD shows Invalid email', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, email: 'a@b');
      await _tapSubmit(tester);
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('whitespace-containing email is invalid', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, email: 'a @b.com');
      await _tapSubmit(tester);
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('email is trimmed on submit', (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _fillValid(tester, email: '  trader@example.com  ');
      await _tapSubmit(tester);
      expect(captured!.email, 'trader@example.com');
    });
  });

  group('SignUpForm password validation', () {
    testWidgets('<8 chars shows length error', (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _fillValid(tester, password: 'short');
      await _tapSubmit(tester);
      expect(
        find.text('At least ${AppConstants.minPasswordLength} characters'),
        findsOneWidget,
      );
    });

    testWidgets('boundary: exactly 8 chars is valid', (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _fillValid(tester, password: '12345678');
      await _tapSubmit(tester);
      expect(captured, isNotNull);
      expect(captured!.password, '12345678');
    });

    testWidgets('password is NOT trimmed (spaces are legitimate chars)',
        (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _fillValid(tester, password: 'password ');
      await _tapSubmit(tester);
      expect(captured!.password, 'password ');
    });
  });

  group('SignUpForm submission behaviour', () {
    testWidgets('valid data → onSubmit called once with all fields',
        (tester) async {
      final submissions = <SignUpSubmission>[];
      await _pump(tester, onSubmit: submissions.add);
      await _fillValid(tester);
      await _tapSubmit(tester);
      expect(submissions.length, 1);
      expect(submissions.first.username, 'tanmay');
      expect(submissions.first.email, 'trader@example.com');
      expect(submissions.first.password, 'hunter2x');
    });

    testWidgets('errors clear in real time as fields become valid',
        (tester) async {
      await _pump(tester, onSubmit: (_) {});
      await _tapSubmit(tester);
      expect(find.text('Required'), findsNWidgets(3));

      await _enter(tester, _usernameKey, 'tanmay');
      await tester.pump();
      expect(find.text('Required'), findsNWidgets(2));

      await _enter(tester, _emailKey, 'trader@example.com');
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      await _enter(tester, _passwordKey, 'hunter2x');
      await tester.pump();
      expect(find.text('Required'), findsNothing);
    });

    testWidgets('pressing Enter in password submits', (tester) async {
      SignUpSubmission? captured;
      await _pump(tester, onSubmit: (s) => captured = s);
      await _fillValid(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
    });

    testWidgets('three rapid submit taps fire exactly three callbacks',
        (tester) async {
      var calls = 0;
      await _pump(tester, onSubmit: (_) => calls++);
      await _fillValid(tester);
      await _tapSubmit(tester);
      await _tapSubmit(tester);
      await _tapSubmit(tester);
      expect(calls, 3);
    });
  });
}
