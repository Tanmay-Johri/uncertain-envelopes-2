import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router_provider.dart';
import 'core/theme/app_theme.dart';
import 'ui/widgets/max_width_centered_layout.dart';

class UncertainEnvelopesApp extends ConsumerWidget {
  /// If [router] is provided it is used as-is (useful for tests that want
  /// a custom [GoRouter]). Otherwise [appRouterProvider] supplies the
  /// production router (auth redirects + refresh).
  const UncertainEnvelopesApp({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = router ?? ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'uncertain-envelopes-2',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: config,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return MaxWidthCenteredLayout(child: child);
      },
    );
  }
}
