import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:uncertain_envelopes_2/core/router/app_router.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/screens/profile/profile_mock_data.dart';
import 'package:uncertain_envelopes_2/ui/screens/profile/profile_screen.dart';
import 'package:uncertain_envelopes_2/ui/screens/profile/profile_view_data.dart';
import 'package:uncertain_envelopes_2/ui/widgets/uncertain_envelopes_logo_mark.dart';

Future<void> _pumpProfile(WidgetTester tester, ProfileScreen screen) async {
  tester.view.physicalSize = const Size(480, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp.router(
      theme: buildAppTheme(),
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => screen),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('mock-home')),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, _) =>
                const Scaffold(body: Text('mock-history-shell')),
          ),
        ],
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'lowercases uppercase typing and shows edit then check when dirty',
    (tester) async {
      final data = mockProfileViewDataDefault().copyWith(
        username: 'start_user',
      );
      await _pumpProfile(tester, ProfileScreen(data: data));

      expect(
        find.byKey(const ValueKey('profile-username-edit-btn')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('profile-username-edit-btn')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('profile-username-submit-btn')),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const ValueKey('profile-username-field')),
        '',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('profile-username-field')),
        'NewNAME',
      );
      await tester.pump();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('profile-username-field')),
            )
            .controller
            ?.text,
        'newname',
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('profile-username-submit-btn')),
            )
            .onPressed,
        isNotNull,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-username-submit-btn')),
      );
      expect(
        find.byKey(const ValueKey('profile-username-submit-btn')),
        findsOneWidget,
      );
    },
  );

  testWidgets('cancel editing restores committed username', (tester) async {
    final data = mockProfileViewDataDefault().copyWith(username: 'keep_me');
    await _pumpProfile(tester, ProfileScreen(data: data));

    await tester.tap(find.byKey(const ValueKey('profile-username-edit-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-username-field')),
      '',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('profile-username-field')),
      'gone',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('profile-username-cancel-edit-btn')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('profile-username-field')),
          )
          .controller
          ?.text,
      'keep_me',
    );
    expect(
      find.byKey(const ValueKey('profile-username-edit-btn')),
      findsOneWidget,
    );
  });

  testWidgets('taken username greys tick and shows banner until text changes', (
    tester,
  ) async {
    final data = mockProfileViewDataDefault().copyWith(username: 'alice');

    await _pumpProfile(
      tester,
      ProfileScreen(
        data: data,
        onUsernameCommit: (u) async {
          if (u == 'bob') return ProfileUsernameSubmitResult.taken;
          return ProfileUsernameSubmitResult.success;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-username-edit-btn')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-username-field')),
      'bob',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('profile-username-submit-btn')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-username-taken-msg')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('profile-username-submit-btn')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey('profile-username-field')),
      'bob2',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('profile-username-taken-msg')),
      findsNothing,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('profile-username-submit-btn')),
          )
          .onPressed,
      isNotNull,
    );

    await tester.enterText(
      find.byKey(const ValueKey('profile-username-field')),
      '',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('profile-username-field')),
      'bob2_ok',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('profile-username-submit-btn')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profile-username-taken-msg')),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('game history taps callback', (tester) async {
    var hits = 0;
    await _pumpProfile(
      tester,
      ProfileScreen(
        data: mockProfileViewDataDefault(),
        onGameHistoryTap: () => hits++,
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-game-history-row')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-game-history-row')));
    await tester.pump();
    expect(hits, 1);
  });

  testWidgets('profile header is back + centered title, no account icon', (
    tester,
  ) async {
    await _pumpProfile(
      tester,
      ProfileScreen(data: mockProfileViewDataDefault()),
    );

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        UncertainEnvelopesLogoMark.kUncertainEnvelopesBrandSemanticsLabel,
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.account_circle_outlined), findsNothing);
  });

  testWidgets('back navigates to home route', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildAppTheme(),
        routerConfig: GoRouter(
          initialLocation: '/p',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(body: Text('at-home')),
            ),
            GoRoute(
              path: '/p',
              builder: (_, _) =>
                  ProfileScreen(data: mockProfileViewDataDefault()),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('at-home'), findsOneWidget);
  });

  testWidgets('shows performance stats from view data', (tester) async {
    await _pumpProfile(
      tester,
      ProfileScreen(
        data: mockProfileViewDataDefault().copyWith(
          winRatePct: 72,
          gamesPlayed: 9,
        ),
      ),
    );
    expect(find.text('WIN RATE'), findsOneWidget);
    expect(find.text('GAMES PLAYED'), findsOneWidget);
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets(
    'single username TextField — email displayed as locked text only',
    (tester) async {
      await _pumpProfile(
        tester,
        ProfileScreen(data: mockProfileViewDataDefault()),
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('EMAIL ADDRESS'), findsOneWidget);
      expect(find.textContaining('example.com'), findsOneWidget);
    },
  );

  testWidgets('sign out invokes callback once', (tester) async {
    var clicks = 0;
    await _pumpProfile(
      tester,
      ProfileScreen(
        data: mockProfileViewDataDefault(),
        onSignOut: () => clicks++,
      ),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-sign-out-btn')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-sign-out-btn')));
    await tester.pump();
    expect(clicks, 1);
  });

  testWidgets(
    'invalid username submit shows snackbar instead of crashing',
    (tester) async {
      await _pumpProfile(
        tester,
        ProfileScreen(
          data: mockProfileViewDataDefault().copyWith(username: 'ok_name'),
          onUsernameCommit: (_) async =>
              ProfileUsernameSubmitResult.success,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('profile-username-edit-btn')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-username-field')),
        'x',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('profile-username-submit-btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  testWidgets(
    'delete account shows confirmation; Back dismisses without callback',
    (tester) async {
      var deletes = 0;
      await _pumpProfile(
        tester,
        ProfileScreen(
          data: mockProfileViewDataDefault(),
          onDeleteAccount: () => deletes++,
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-delete-account-btn')),
      );
      await tester.tap(find.byKey(const ValueKey('profile-delete-account-btn')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Back'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(deletes, 0);
    },
  );

  testWidgets(
    'delete account confirms and invokes callback exactly once',
    (tester) async {
      var deletes = 0;
      await _pumpProfile(
        tester,
        ProfileScreen(
          data: mockProfileViewDataDefault(),
          onDeleteAccount: () => deletes++,
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('profile-delete-account-btn')),
      );
      await tester.tap(find.byKey(const ValueKey('profile-delete-account-btn')));
      await tester.pumpAndSettle();

      final confirmInDialog = find.descendant(
        of: find.byType(Dialog),
        matching: find.widgetWithText(FilledButton, 'Delete account'),
      );
      await tester.tap(confirmInDialog);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(deletes, 1);
    },
  );
}
