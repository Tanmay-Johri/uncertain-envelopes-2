import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Wall clock. Overridden by tests to make time deterministic.
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) => DateTime.now;

/// One-second ticker used to drive the countdown timer provider. Each
/// emitted value IS the wall-clock instant at the moment of the tick, so
/// the timer provider only needs to compute `endTime - tick`.
///
/// Tests should override this with a `StreamController.broadcast()` and
/// push custom [DateTime] values. Without an override, a real periodic
/// timer is used.
@Riverpod(keepAlive: true)
Stream<DateTime> timerTickStream(Ref ref) {
  final clockFn = ref.watch(clockProvider);
  late StreamController<DateTime> controller;
  Timer? timer;
  controller = StreamController<DateTime>.broadcast(
    onListen: () {
      controller.add(clockFn());
      timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => controller.add(clockFn()),
      );
    },
    onCancel: () {
      timer?.cancel();
      timer = null;
    },
  );
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
}
