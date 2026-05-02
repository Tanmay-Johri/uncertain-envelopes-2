import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/core/account/profile_username_rules.dart';
import 'package:uncertain_envelopes_2/core/constants/app_constants.dart';

void main() {
  group('validateUsernameForProfile', () {
    test('accepts valid lowercase slug', () {
      expect(validateUsernameForProfile('cryptoking99'), isNull);
      expect(validateUsernameForProfile('  ab_c-12  '), isNull);
    });

    test('rejects empty and short', () {
      expect(validateUsernameForProfile(''), isNotNull);
      final msg = validateUsernameForProfile('ab');
      expect(msg, isNotNull);
      expect(msg!, contains('${AppConstants.minUsernameLength}'));
    });

    test('rejects too long', () {
      expect(
        validateUsernameForProfile('a' * (AppConstants.maxUsernameLength + 1)),
        isNotNull,
      );
    });

    test('rejects illegal characters', () {
      expect(validateUsernameForProfile('oops space'), isNotNull);
      expect(validateUsernameForProfile('Aa'), isNotNull);
      expect(validateUsernameForProfile('user@bad'), isNotNull);
    });
  });
}
