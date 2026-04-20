import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class UncertainEnvelopesApp extends StatelessWidget {
  /// If [router] is provided it is used as-is (useful for tests that want
  /// to start at a specific deep-link). Otherwise the default router is
  /// built from [buildAppRouter].
  UncertainEnvelopesApp({super.key, GoRouter? router})
      : _router = router ?? buildAppRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'uncertain-envelopes-2',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
