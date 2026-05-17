import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/app.dart';
import 'package:uncertain_envelopes_2/bootstrap/supabase_bootstrap_gate.dart';
import 'package:uncertain_envelopes_2/data/repositories/in_memory_auth_repository.dart';
import 'package:uncertain_envelopes_2/providers/auth_provider.dart';
import 'package:uncertain_envelopes_2/ui/widgets/app_shell.dart';
import 'package:uncertain_envelopes_2/ui/widgets/uncertain_envelopes_logo_mark.dart';

void main() {
  testWidgets('App renders without crashing and lands on the shell',
      (tester) async {
    final authRepo = InMemoryAuthRepository();
    await authRepo.signUp(
      email: 'widget@test.co',
      password: 'password12',
      username: 'widgetuser',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
        child: SupabaseBootstrapGate(
          // Real Supabase starts auth auto-refresh timers; avoid pending timers
          // in widget tests while the UI stack does not yet depend on Supabase.
          initializer: () async {},
          child: const UncertainEnvelopesApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        UncertainEnvelopesLogoMark.kUncertainEnvelopesBrandSemanticsLabel,
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
