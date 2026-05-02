import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/formatting/order_created_at_display.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'formatOrderCreatedUtcForUi uses short date without weekday prefix',
    (tester) async {
      late String out;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) {
              out = formatOrderCreatedUtcForUi(
                context,
                DateTime.utc(2026, 5, 3, 15, 30),
              );
              return const SizedBox.expand();
            },
          ),
        ),
      );

      expect(out, contains('·'));
      expect(out, contains('May'));
      expect(out, isNot(contains('Sunday')));
      expect(out, contains('2026'));
    },
  );
}
