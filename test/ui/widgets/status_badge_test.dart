import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/status_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(theme: buildAppTheme(), home: Scaffold(body: child)),
  );
}

Color _textColor(WidgetTester tester, String label) {
  final text = tester.widget<Text>(find.text(label));
  return text.style!.color!;
}

void main() {
  group('StatusBadge labels', () {
    testWidgets('renders ACTIVE for active', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.active),
      );
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('renders JOINED, READY, NOT JOINED', (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            StatusBadge(status: GameStatusBadge.joined),
            StatusBadge(status: GameStatusBadge.ready),
            StatusBadge(status: GameStatusBadge.notJoined),
          ],
        ),
      );
      expect(find.text('JOINED'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('NOT JOINED'), findsOneWidget);
    });
  });

  group('StatusBadge colors', () {
    testWidgets('ACTIVE uses green foreground', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.active),
      );
      expect(_textColor(tester, 'ACTIVE'), const Color(0xFF4ADE80));
    });

    testWidgets('READY uses blue foreground', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.ready),
      );
      expect(_textColor(tester, 'READY'), const Color(0xFF60A5FA));
    });

    testWidgets('JOINED uses yellow foreground on tinted chip', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.joined),
      );
      expect(_textColor(tester, 'JOINED'), const Color(0xFFFACC15));
    });

    testWidgets('NOT JOINED uses slate foreground', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.notJoined),
      );
      expect(_textColor(tester, 'NOT JOINED'), const Color(0xFF94A3B8));
    });
  });
}
