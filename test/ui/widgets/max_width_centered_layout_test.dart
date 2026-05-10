import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/widgets/max_width_centered_layout.dart';

void main() {
  group('MaxWidthCenteredLayout', () {
    testWidgets('uses full width when viewport is below cap', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MaxWidthCenteredLayout(
            maxContentWidth: 960,
            child: SizedBox(
              key: Key('inner'),
              height: 100,
              child: Placeholder(),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('inner'))).width, 600);
    });

    testWidgets('caps width at maxContentWidth on wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MaxWidthCenteredLayout(
            maxContentWidth: 960,
            child: SizedBox(
              key: Key('inner'),
              height: 100,
              child: Placeholder(),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byKey(const Key('inner'))).width, 960);
    });
  });
}
