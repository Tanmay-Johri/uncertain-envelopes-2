import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/confirmation_dialog.dart';
import 'package:uncertain_envelopes_2/ui/widgets/neon_button.dart';

Future<bool?> _openAndTap(
  WidgetTester tester, {
  required String buttonLabel,
  bool destructive = false,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  String? message,
}) async {
  late Future<bool?> resultFuture;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                resultFuture = ConfirmationDialog.show(
                  context,
                  title: 'Kick player?',
                  message: message,
                  confirmLabel: confirmLabel,
                  cancelLabel: cancelLabel,
                  destructive: destructive,
                );
              },
              child: const Text('OPEN'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('OPEN'));
  await tester.pumpAndSettle();

  // The NeonButton uppercases its label internally.
  await tester.tap(find.text(buttonLabel.toUpperCase()));
  await tester.pumpAndSettle();

  return resultFuture;
}

void main() {
  group('ConfirmationDialog', () {
    testWidgets('renders title and message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  ctx,
                  title: 'Kick player?',
                  message: 'Jane will lose her spot.',
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('Kick player?'), findsOneWidget);
      expect(find.text('Jane will lose her spot.'), findsOneWidget);
    });

    testWidgets('omits message when not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  ctx,
                  title: 'Are you sure?',
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('confirm returns true', (tester) async {
      final result = await _openAndTap(tester, buttonLabel: 'Confirm');
      expect(await result, isTrue);
    });

    testWidgets('cancel returns false', (tester) async {
      final result = await _openAndTap(tester, buttonLabel: 'Cancel');
      expect(await result, isFalse);
    });

    testWidgets('custom labels render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  ctx,
                  title: 't',
                  confirmLabel: 'Kick',
                  cancelLabel: 'Keep',
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('KICK'), findsOneWidget);
      expect(find.text('KEEP'), findsOneWidget);
    });

    testWidgets('destructive=true makes confirm red, cancel outline',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  ctx,
                  title: 't',
                  destructive: true,
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<NeonButton>(find.byType(NeonButton));
      expect(buttons.length, 2);
      // Cancel button (first) is outline, confirm button (second) is
      // destructive red.
      expect(buttons.elementAt(0).variant, NeonButtonVariant.outline);
      expect(buttons.elementAt(1).variant, NeonButtonVariant.destructive);
    });

    testWidgets('destructive=false makes confirm primary green',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ConfirmationDialog.show(
                  ctx,
                  title: 't',
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      final buttons = tester.widgetList<NeonButton>(find.byType(NeonButton));
      expect(buttons.elementAt(1).variant, NeonButtonVariant.primary);
    });

    testWidgets('dismissing by tapping barrier returns null', (tester) async {
      late Future<bool?> result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  result = ConfirmationDialog.show(
                    ctx,
                    title: 't',
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Tap the barrier at the top of the screen (outside the dialog card).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });
  });
}
