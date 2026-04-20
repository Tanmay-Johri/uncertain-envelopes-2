import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/app.dart';
import 'package:uncertain_envelopes_2/ui/widgets/app_shell.dart';

void main() {
  testWidgets('App renders without crashing and lands on the shell',
      (tester) async {
    await tester.pumpWidget(UncertainEnvelopesApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('UNCERTAIN ENVELOPES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
