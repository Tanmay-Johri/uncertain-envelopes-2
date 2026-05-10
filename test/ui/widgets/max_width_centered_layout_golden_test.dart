import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/max_width_centered_layout.dart';

/// POL1: regression snapshots at three logical widths (Phase 3 §3.1).
void main() {
  const rootKey = ValueKey<String>('pol1-max-width-root');

  Future<void> pumpAtWidth(WidgetTester tester, double width) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });
    await binding.setSurfaceSize(Size(width, 600));

    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: MaxWidthCenteredLayout(
            child: SizedBox(
              width: double.infinity,
              height: 400,
              child: Center(
                child: Text(
                  'POL1 width ${width.toInt()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('MaxWidthCenteredLayout breakpoint goldens', () {
    testWidgets('375 logical width', (tester) async {
      await pumpAtWidth(tester, 375);
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/max_width_layout_375.png'),
      );
    });

    testWidgets('768 logical width', (tester) async {
      await pumpAtWidth(tester, 768);
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/max_width_layout_768.png'),
      );
    });

    testWidgets('1280 logical width', (tester) async {
      await pumpAtWidth(tester, 1280);
      await expectLater(
        find.byKey(rootKey),
        matchesGoldenFile('goldens/max_width_layout_1280.png'),
      );
    });
  });
}
