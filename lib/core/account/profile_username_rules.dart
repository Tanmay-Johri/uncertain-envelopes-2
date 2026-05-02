import '../constants/app_constants.dart';

/// Characters allowed once normalized to lowercase (matches signup intent).
final RegExp profileUsernameCharsetPattern = RegExp(r'^[a-z0-9_-]+$');

/// Inline validation before calling [onUsernameCommit] (Stream C guardrails).
///
/// Trimmed lowercase [candidate] → `null` if OK, otherwise a short UI message.
String? validateUsernameForProfile(String candidate) {
  final t = candidate.trim();
  if (t.length < AppConstants.minUsernameLength) {
    return 'At least ${AppConstants.minUsernameLength} characters';
  }
  if (t.length > AppConstants.maxUsernameLength) {
    return 'At most ${AppConstants.maxUsernameLength} characters';
  }
  if (!profileUsernameCharsetPattern.hasMatch(t)) {
    return 'Letters, digits, underscores, and hyphen only';
  }
  return null;
}
