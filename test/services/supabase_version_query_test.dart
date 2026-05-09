import 'package:flutter_test/flutter_test.dart';
import 'package:uncertain_envelopes_2/services/supabase_version_query.dart';

void main() {
  group('SupabaseVersionQuery', () {
    test('returns int when row present', () async {
      final q = SupabaseVersionQuery.withFetch(
        (_) async => {'state_version': 7},
      );
      expect(await q.readVersion('any-id'), 7);
    });

    test('returns null when row missing', () async {
      final q = SupabaseVersionQuery.withFetch((_) async => null);
      expect(await q.readVersion('missing'), isNull);
    });

    test('returns null on fetch throw (RLS / network analogue)', () async {
      final q = SupabaseVersionQuery.withFetch(
        (_) async => throw Exception('postgrest'),
      );
      expect(await q.readVersion('g1'), isNull);
    });

    test('coerces num to int', () async {
      final q = SupabaseVersionQuery.withFetch(
        (_) async => {'state_version': 12.0},
      );
      expect(await q.readVersion('g1'), 12);
    });

    test('returns null when state_version missing or wrong type', () async {
      final q = SupabaseVersionQuery.withFetch((_) async => {'other': 1});
      expect(await q.readVersion('g1'), isNull);
    });
  });
}
