import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uncertain_envelopes_2/bootstrap/supabase_bootstrap.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test(
      'initializeSupabase with memory auth is idempotent and exposes client',
      () async {
    final auth = supabaseAuthOptionsWithoutPlugins();
    await initializeSupabase(authOptions: auth);
    expect(Supabase.instance.isInitialized, isTrue);
    expect(Supabase.instance.client.auth.currentUser, isNull);
    await initializeSupabase(authOptions: auth);
    expect(Supabase.instance.isInitialized, isTrue);
  });
}
