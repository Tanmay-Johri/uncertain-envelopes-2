import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/app.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(const UncertainEnvelopesApp());
    expect(find.text('uncertain-envelopes-2'), findsOneWidget);
  });
}
