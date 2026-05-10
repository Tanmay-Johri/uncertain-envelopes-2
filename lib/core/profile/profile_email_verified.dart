/// Whether Supabase GoTrue considers the email confirmed.
///
/// [emailConfirmedAt] is `User.emailConfirmedAt` (RFC3339 string or null).
bool isAuthEmailConfirmed(String? emailConfirmedAt) =>
    emailConfirmedAt != null && emailConfirmedAt.isNotEmpty;
