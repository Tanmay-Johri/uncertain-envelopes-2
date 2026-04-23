import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/theme/app_theme.dart';
import 'package:uncertain_envelopes_2/ui/widgets/code_input.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

Finder _cell(int i) => find.byKey(ValueKey('code_cell_$i'));

void main() {
  group('CodeInput rendering', () {
    testWidgets('renders five text fields', (tester) async {
      await _pump(tester, const CodeInput());
      expect(find.byType(TextField), findsNWidgets(5));
    });

    testWidgets('each cell TextField expands to fill square height', (
      tester,
    ) async {
      await _pump(tester, const CodeInput());
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        final tf = tester.widget<TextField>(_cell(i));
        expect(tf.expands, isTrue);
        expect(tf.minLines, isNull);
        expect(tf.maxLines, isNull);
      }
    });

    testWidgets('initialCode seeds first cells', (tester) async {
      await _pump(
        tester,
        const CodeInput(initialCode: 'ab12'),
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(_cell(0)).controller!.text,
        'A',
      );
      expect(
        tester.widget<TextField>(_cell(1)).controller!.text,
        'B',
      );
      expect(
        tester.widget<TextField>(_cell(2)).controller!.text,
        '1',
      );
      expect(
        tester.widget<TextField>(_cell(3)).controller!.text,
        '2',
      );
      expect(
        tester.widget<TextField>(_cell(4)).controller!.text,
        '',
      );
    });

    testWidgets('initialCode strips non-alnum', (tester) async {
      await _pump(
        tester,
        const CodeInput(initialCode: 'a-b_c'),
      );
      await tester.pump();
      expect(tester.widget<TextField>(_cell(0)).controller!.text, 'A');
      expect(tester.widget<TextField>(_cell(1)).controller!.text, 'B');
      expect(tester.widget<TextField>(_cell(2)).controller!.text, 'C');
    });
  });

  group('CodeInput typing', () {
    testWidgets('typing advances focus and builds code', (tester) async {
      final codes = <String>[];
      await _pump(
        tester,
        CodeInput(onChanged: codes.add),
      );
      await tester.pump();

      await tester.tap(_cell(0));
      await tester.pump();
      await tester.enterText(_cell(0), 'X');
      await tester.pump();
      expect(codes.last, 'X');
      expect(tester.widget<TextField>(_cell(1)).focusNode?.hasFocus, isTrue);

      await tester.enterText(_cell(1), 'Y');
      await tester.pump();
      expect(codes.last, 'XY');

      await tester.enterText(_cell(2), 'Z');
      await tester.pump();
      await tester.enterText(_cell(3), 'W');
      await tester.pump();
      await tester.enterText(_cell(4), 'Q');
      await tester.pump();
      expect(codes.last, 'XYZWQ');
    });

    testWidgets('onCompleted fires once when fifth char lands', (tester) async {
      var completed = 0;
      String? last;
      await _pump(
        tester,
        CodeInput(
          onCompleted: (c) {
            completed++;
            last = c;
          },
        ),
      );
      await tester.pump();
      await tester.tap(_cell(0));
      await tester.pump();

      for (final ch in ['1', '2', '3', '4', '5']) {
        final index = '12345'.indexOf(ch);
        await tester.enterText(_cell(index), ch);
        await tester.pump();
      }
      expect(completed, 1);
      expect(last, '12345');
    });
  });

  group('CodeInput paste', () {
    testWidgets('pasting into first cell fills forward', (tester) async {
      final codes = <String>[];
      await _pump(
        tester,
        CodeInput(onChanged: codes.add),
      );
      await tester.pump();
      await tester.tap(_cell(0));
      await tester.pump();
      await tester.enterText(_cell(0), 'ABCDE');
      await tester.pump();
      expect(codes.last, 'ABCDE');
      for (var i = 0; i < 5; i++) {
        expect(
          tester.widget<TextField>(_cell(i)).controller!.text,
          'ABCDE'[i],
        );
      }
    });

    testWidgets('paste from middle cell only fills remaining slots',
        (tester) async {
      await _pump(tester, const CodeInput(initialCode: '12'));
      await tester.pump();
      await tester.tap(_cell(2));
      await tester.pump();
      await tester.enterText(_cell(2), 'XYZ');
      await tester.pump();
      expect(tester.widget<TextField>(_cell(0)).controller!.text, '1');
      expect(tester.widget<TextField>(_cell(1)).controller!.text, '2');
      expect(tester.widget<TextField>(_cell(2)).controller!.text, 'X');
      expect(tester.widget<TextField>(_cell(3)).controller!.text, 'Y');
      expect(tester.widget<TextField>(_cell(4)).controller!.text, 'Z');
    });

    testWidgets('long paste is truncated to five total', (tester) async {
      await _pump(tester, const CodeInput());
      await tester.pump();
      await tester.tap(_cell(0));
      await tester.pump();
      await tester.enterText(_cell(0), 'ABCDEFGH');
      await tester.pump();
      expect(tester.widget<TextField>(_cell(4)).controller!.text, 'E');
    });
  });

  group('CodeInput backspace', () {
    testWidgets('backspace on empty cell clears previous and moves focus',
        (tester) async {
      await _pump(tester, const CodeInput(initialCode: 'AB'));
      await tester.pump();
      await tester.tap(_cell(2));
      await tester.pump();
      expect(tester.widget<TextField>(_cell(2)).focusNode?.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(tester.widget<TextField>(_cell(1)).controller!.text, '');
      expect(tester.widget<TextField>(_cell(1)).focusNode?.hasFocus, isTrue);
    });
  });

  group('CodeInput adversarial', () {
    testWidgets('rapid sequential entry still yields full code', (tester) async {
      final codes = <String>[];
      await _pump(
        tester,
        CodeInput(onChanged: codes.add),
      );
      await tester.pump();
      await tester.tap(_cell(0));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.enterText(_cell(i), 'QWERT'[i]);
        await tester.pump();
      }
      expect(codes.last, 'QWERT');
    });
  });
}
