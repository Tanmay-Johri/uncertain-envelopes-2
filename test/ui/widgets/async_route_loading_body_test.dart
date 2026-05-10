import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/widgets/async_route_loading_body.dart';

void main() {
  testWidgets('shows spinner and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AsyncRouteLoadingBody(message: 'Loading test…'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading test…'), findsOneWidget);
  });
}
