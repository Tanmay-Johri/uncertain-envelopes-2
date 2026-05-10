import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/profile/profile_email_verified.dart';

void main() {
  group('isAuthEmailConfirmed', () {
    test('false when both confirmation fields are null or empty', () {
      expect(isAuthEmailConfirmed(null), isFalse);
      expect(isAuthEmailConfirmed(''), isFalse);
    });

    test('true when emailConfirmedAt is non-empty', () {
      expect(isAuthEmailConfirmed('2026-01-01T00:00:00Z'), isTrue);
    });
  });
}
