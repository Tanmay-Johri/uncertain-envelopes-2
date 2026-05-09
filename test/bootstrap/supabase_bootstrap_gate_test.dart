import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/bootstrap/supabase_bootstrap_gate.dart';

void main() {
  testWidgets('shows loading shell until initializer completes', (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: SupabaseBootstrapGate(
          initializer: () => completer.future,
          child: const Text('INNER_APP'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('UNCERTAIN ENVELOPES'), findsOneWidget);
    expect(find.text('INNER_APP'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.text('INNER_APP'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows error and retry runs initializer again', (tester) async {
    var attempts = 0;
    Future<void> flakyInit() async {
      attempts++;
      if (attempts < 2) {
        throw Exception('simulated_init_failure');
      }
    }

    await tester.pumpWidget(
      MaterialApp(
        home: SupabaseBootstrapGate(
          initializer: flakyInit,
          child: const Text('OK'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not start'), findsOneWidget);
    expect(find.textContaining('simulated_init_failure'), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('OK'), findsOneWidget);
    expect(attempts, 2);
  });
}
