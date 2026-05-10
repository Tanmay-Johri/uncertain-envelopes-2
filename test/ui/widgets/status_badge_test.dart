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
    testWidgets('renders PLAYING for playing', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.playing),
      );
      expect(find.text('PLAYING'), findsOneWidget);
    });

    testWidgets('renders JOINED, ENDED, NOT JOINED', (tester) async {
      await _pump(
        tester,
        const Column(
          children: [
            StatusBadge(status: GameStatusBadge.joined),
            StatusBadge(status: GameStatusBadge.ended),
            StatusBadge(status: GameStatusBadge.notJoined),
          ],
        ),
      );
      expect(find.text('JOINED'), findsOneWidget);
      expect(find.text('ENDED'), findsOneWidget);
      expect(find.text('NOT JOINED'), findsOneWidget);
    });
  });

  group('StatusBadge colors', () {
    testWidgets('PLAYING uses green foreground', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.playing),
      );
      expect(_textColor(tester, 'PLAYING'), const Color(0xFF4ADE80));
    });

    testWidgets('ENDED uses light slate foreground', (tester) async {
      await _pump(
        tester,
        const StatusBadge(status: GameStatusBadge.ended),
      );
      expect(_textColor(tester, 'ENDED'), const Color(0xFFE2E8F0));
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
