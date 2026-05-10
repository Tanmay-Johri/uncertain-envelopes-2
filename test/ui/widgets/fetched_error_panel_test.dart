import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/fetched_error_panel.dart';

void main() {
  testWidgets('FetchedErrorPanel shows message and invokes onRetry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: FetchedErrorPanel(
            message: 'Something failed',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Something failed'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    await tester.tap(find.byKey(FetchedErrorPanel.retryButtonKey));
    expect(retries, 1);
  });
}
