import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/providers/_environment.dart';

void main() {
  test('useRealBackend tracks compile-time USE_REAL_BACKEND', () {
    const expected = bool.fromEnvironment(
      'USE_REAL_BACKEND',
      defaultValue: false,
    );
    expect(useRealBackend, expected);
  });
}
