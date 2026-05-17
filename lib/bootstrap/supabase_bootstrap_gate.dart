import 'package:flutter/material.dart';

import 'supabase_bootstrap.dart';

/// Paints a minimal shell immediately, then runs [initializer] before showing
/// [child].
///
/// Avoids a blank Flutter canvas while `Supabase.initialize` (network + auth
/// restore) runs — that work used to block `runApp` in [main.dart].
class SupabaseBootstrapGate extends StatefulWidget {
  const SupabaseBootstrapGate({
    super.key,
    required this.child,
    this.initializer,
  });

  final Widget child;

  /// Defaults to [initializeSupabase]. Tests may pass a variant with
  /// [supabaseAuthOptionsWithoutPlugins].
  final Future<void> Function()? initializer;

  @override
  State<SupabaseBootstrapGate> createState() => _SupabaseBootstrapGateState();
}

class _SupabaseBootstrapGateState extends State<SupabaseBootstrapGate> {
  late Future<void> _bootstrapFuture;
  int _retryGeneration = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _runInit();
  }

  Future<void> _runInit() {
    final init = widget.initializer ?? initializeSupabase;
    return init();
  }

  void _retry() {
    setState(() {
      _retryGeneration++;
      _bootstrapFuture = _runInit();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      key: ValueKey<int>(_retryGeneration),
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapShell();
        }
        if (snapshot.hasError) {
          return _BootstrapError(
            error: snapshot.error!,
            stackTrace: snapshot.stackTrace,
            onRetry: _retry,
          );
        }
        return widget.child;
      },
    );
  }
}

class _BootstrapShell extends StatelessWidget {
  const _BootstrapShell();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF1F1F1F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF40F320),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'UNCERTAIN ENVELOPES',
                style: TextStyle(
                  color: Color(0xFF40F320),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({
    required this.error,
    required this.stackTrace,
    required this.onRetry,
  });

  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1F1F1F),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Could not start',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$error',
                    style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 13),
                  ),
                  if (stackTrace != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '$stackTrace',
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF707070),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
