import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/ui/widgets/game_realtime_session_scope.dart';

void main() {
  testWidgets('GameRealtimeSessionScope builds child for non-empty gameId',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GameRealtimeSessionScope(
            gameId: 'g-1',
            child: const Scaffold(body: Text('inner')),
          ),
        ),
      ),
    );
    expect(find.text('inner'), findsOneWidget);
  });

  testWidgets('GameRealtimeSessionScope skips watch when gameId empty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GameRealtimeSessionScope(
            gameId: '',
            child: const Scaffold(body: Text('blank-id')),
          ),
        ),
      ),
    );
    expect(find.text('blank-id'), findsOneWidget);
  });
}
