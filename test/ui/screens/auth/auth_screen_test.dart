import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_spacing.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/auth_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/login_form.dart';
import 'package:uncertain_envelopes_2/ui/screens/auth/sign_up_form.dart';
import 'package:uncertain_envelopes_2/ui/widgets/auth_tab_switcher.dart';
import 'package:uncertain_envelopes_2/ui/widgets/uncertain_envelopes_logo_mark.dart';

Future<void> _pump(
  WidgetTester tester, {
  AuthTab initial = AuthTab.logIn,
  ValueChanged<LoginSubmission>? onLogIn,
  ValueChanged<SignUpSubmission>? onSignUp,
  VoidCallback? onForgot,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: AuthScreen(
        initialTab: initial,
        onLogIn: onLogIn,
        onSignUp: onSignUp,
        onForgotPassword: onForgot,
      ),
    ),
  );
}

void main() {
  group('AuthScreen layout', () {
    testWidgets('renders brand header and the card', (tester) async {
      await _pump(tester);
      expect(
        find.bySemanticsLabel(
          UncertainEnvelopesLogoMark.kUncertainEnvelopesBrandSemanticsLabel,
        ),
        findsOneWidget,
      );
      expect(find.byType(AuthTabSwitcher), findsOneWidget);
    });

    testWidgets('default initial tab shows LoginForm', (tester) async {
      await _pump(tester);
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('initialTab=signUp shows SignUpForm', (tester) async {
      await _pump(tester, initial: AuthTab.signUp);
      expect(find.byType(SignUpForm), findsOneWidget);
      expect(find.byKey(const Key('signup_submit_button')), findsOneWidget);
    });
  });

  group('AuthScreen tab switching', () {
    testWidgets('tapping SIGN UP switches visible form', (tester) async {
      await _pump(tester);
      expect(find.byType(LoginForm), findsOneWidget);
      await tester.tap(find.text('SIGN UP'));
      await tester.pumpAndSettle();
      expect(find.byType(SignUpForm), findsOneWidget);
      expect(find.byKey(const Key('signup_submit_button')), findsOneWidget);
    });

    testWidgets('tapping LOG IN after being on Sign Up switches back',
        (tester) async {
      await _pump(tester, initial: AuthTab.signUp);
      expect(find.byType(SignUpForm), findsOneWidget);
      await tester.tap(find.text('LOG IN'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginForm), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets(
      'card height follows the visible form — '
      'switching back to LogIn does not inherit SignUp height',
      (tester) async {
        await _pump(tester);
        // Measure the login-card height with LogIn form visible.
        final cardBefore = tester.getSize(find.byType(AuthTabSwitcher));
        final heightBefore = tester
            .getSize(find.ancestor(
              of: find.byType(AuthTabSwitcher),
              matching: find.byType(Column),
            ).first)
            .height;

        // Switch to SignUp then back.
        await tester.tap(find.text('SIGN UP'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('LOG IN'));
        await tester.pumpAndSettle();

        final heightAfter = tester
            .getSize(find.ancestor(
              of: find.byType(AuthTabSwitcher),
              matching: find.byType(Column),
            ).first)
            .height;
        expect(heightAfter, closeTo(heightBefore, 0.5));
        // Sanity: the tab-bar width itself didn't move.
        expect(tester.getSize(find.byType(AuthTabSwitcher)), cardBefore);
      },
    );

    testWidgets('form field state is preserved when switching tabs',
        (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const Key('login_identifier_field')),
        'tanmay',
      );
      await tester.tap(find.text('SIGN UP'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LOG IN'));
      await tester.pumpAndSettle();
      expect(find.text('tanmay'), findsOneWidget);
    });
  });

  group('AuthScreen submissions', () {
    testWidgets('valid login bubbles up to onLogIn with trimmed identifier',
        (tester) async {
      LoginSubmission? captured;
      await _pump(tester, onLogIn: (s) => captured = s);
      await tester.enterText(
        find.byKey(const Key('login_identifier_field')),
        '  tanmay  ',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'hunter2',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.identifier, 'tanmay');
    });

    testWidgets('valid sign-up bubbles up to onSignUp with normalized data',
        (tester) async {
      SignUpSubmission? captured;
      await _pump(
        tester,
        initial: AuthTab.signUp,
        onSignUp: (s) => captured = s,
      );
      await tester.enterText(
        find.byKey(const Key('signup_username_field')),
        'TanMay',
      );
      await tester.enterText(
        find.byKey(const Key('signup_email_field')),
        'trader@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signup_password_field')),
        'hunter2x',
      );
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pumpAndSettle();
      expect(captured, isNotNull);
      expect(captured!.username, 'tanmay');
      expect(captured!.email, 'trader@example.com');
    });

    testWidgets('missing callbacks do not crash on submit', (tester) async {
      await _pump(tester);
      await tester.enterText(
        find.byKey(const Key('login_identifier_field')),
        'tanmay',
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        'hunter2',
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Forgot? on login side fires onForgotPassword',
        (tester) async {
      var tapped = 0;
      await _pump(tester, onForgot: () => tapped++);
      await tester.tap(find.text('FORGOT?'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });
  });

  group('AuthScreen viewport behavior', () {
    testWidgets('renders at 360x640 (small phone) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await _pump(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders at 1440x900 (desktop) without overflow and centered',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await _pump(tester);
      expect(tester.takeException(), isNull);
      // The card should be width-capped (maxWidth: 440) even on wide
      // viewports.
      final cardWidth = tester.getSize(find.byType(AuthTabSwitcher)).width;
      expect(cardWidth, lessThanOrEqualTo(440));
    });

    testWidgets(
        'short viewport scrolls the card instead of crushing it',
        (tester) async {
      tester.view.physicalSize = const Size(400, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await _pump(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets(
      'tall viewport pins the title at the top and vertically centres the card',
      (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        await _pump(tester);

        final titleRect = tester.getRect(
          find.bySemanticsLabel(
            UncertainEnvelopesLogoMark.kUncertainEnvelopesBrandSemanticsLabel,
          ),
        );
        final cardRect = tester.getRect(
          find.ancestor(
            of: find.byType(AuthTabSwitcher),
            matching: find.byType(ClipRRect),
          ).first,
        );
        final safeRect = tester.getRect(find.byType(SafeArea));

        expect(titleRect.top, closeTo(safeRect.top + 16, 12));
        expect(
          cardRect.top,
          greaterThanOrEqualTo(titleRect.bottom + AppSpacing.xxxl - 4),
        );

        final paneTop = titleRect.bottom + AppSpacing.xxxl;
        final paneBottom = safeRect.bottom;
        final paneMidY = (paneTop + paneBottom) / 2;
        expect(cardRect.center.dy, closeTo(paneMidY, 56));
      },
    );
  });
}
