/// Outcome when the user commits a renamed username (mock or API).
enum ProfileUsernameSubmitResult {
  success,

  /// Chosen username is unavailable (duplicate).
  taken,
}

/// Read model for **`ProfileScreen`** (Stream **C8** mock path).
class ProfileViewData {
  ProfileViewData({
    required String username,
    required this.email,
    required this.emailVerified,
    required this.winRatePct,
    required this.gamesPlayed,
  }) : username = username.trim().toLowerCase();

  final String username;
  final String email;
  final bool emailVerified;

  /// 0–100 for display (**`--`** formatting left to UI if null later).
  final int winRatePct;
  final int gamesPlayed;

  ProfileViewData copyWith({
    String? username,
    String? email,
    bool? emailVerified,
    int? winRatePct,
    int? gamesPlayed,
  }) {
    return ProfileViewData(
      username: username != null
          ? username.trim().toLowerCase()
          : this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      winRatePct: winRatePct ?? this.winRatePct,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    );
  }
}
