import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bootstrap/supabase_bootstrap.dart';
import '../../core/profile/profile_email_verified.dart';
import '../../data/repositories/player_repository.dart';
import '../../ui/screens/profile/profile_view_data.dart';
import '../_environment.dart';
import '../auth_provider.dart';
import '../player_repository_provider.dart';

part 'profile_view_data_provider.g.dart';

/// Thrown when [profileViewDataProvider] cannot build (e.g. not signed in).
class ProfileViewDataException implements Exception {
  const ProfileViewDataException(this.message);
  final String message;

  @override
  String toString() => 'ProfileViewDataException($message)';
}

/// Profile header fields for [ProfileScreen] (Phase 2B.7).
///
/// Stats come from [PlayerRepository.fetchPerformanceStats]. When the
/// ranked-stats RPC is missing or errors (B-GAP-2), falls back to zeros.
/// With `USE_REAL_BACKEND` and an initialised Supabase client,
/// [ProfileViewData.emailVerified] reflects Auth `emailConfirmedAt`; otherwise
/// it stays `true` for in-memory / bootstrap.
@riverpod
Future<ProfileViewData> profileViewData(Ref ref) async {
  final player = ref.watch(authControllerProvider).valueOrNull;
  if (player == null) {
    throw const ProfileViewDataException('Sign in to view your profile.');
  }

  final playerRepo = ref.watch(playerRepositoryProvider);
  PlayerStats stats;
  try {
    stats = await playerRepo.fetchPerformanceStats(player.playerId);
  } catch (_) {
    stats = const PlayerStats(gamesPlayed: 0, wins: 0);
  }

  final winRatePct = stats.gamesPlayed == 0
      ? 0
      : (stats.winRate * 100).round().clamp(0, 100);

  late final bool emailVerified;
  if (!useRealBackend) {
    emailVerified = true;
  } else if (!isSupabaseClientAvailable) {
    emailVerified = true;
  } else {
    emailVerified = isAuthEmailConfirmed(
      Supabase.instance.client.auth.currentUser?.emailConfirmedAt,
    );
  }

  return ProfileViewData(
    username: player.username,
    email: player.email,
    emailVerified: emailVerified,
    winRatePct: winRatePct,
    gamesPlayed: stats.gamesPlayed,
  );
}
