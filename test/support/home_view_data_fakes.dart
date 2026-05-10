import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uncertain_envelopes_2/providers/view_data/home_view_data_provider.dart';
import 'package:uncertain_envelopes_2/ui/screens/home/home_mock_data.dart';

/// Stable joined/public rows for router/widget tests without touching repositories.
class HomeViewDataKMockGames extends HomeViewData {
  @override
  Future<List<MockHomeGame>> build() async => kMockHomeGames;

  @override
  Future<void> silentRefresh() async {
    state = AsyncValue.data(kMockHomeGames);
  }
}

/// Loading-state widget test: brief delay then an empty list.
class HomeViewDataDelayedEmpty extends HomeViewData {
  @override
  Future<List<MockHomeGame>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    return const [];
  }
}

/// Forces an error surface on first resolution (before Retry / silentRefresh).
class HomeViewDataThrowsNetwork extends HomeViewData {
  @override
  Future<List<MockHomeGame>> build() async => throw StateError('network');
}

/// First fetch fails; [silentRefresh] (Retry) performs the second successful fetch.
class HomeViewDataRetryOnce extends HomeViewData {
  var _calls = 0;

  Future<List<MockHomeGame>> _fetch() async {
    _calls++;
    if (_calls == 1) throw StateError('offline');
    return const [];
  }

  @override
  Future<List<MockHomeGame>> build() => _fetch();

  @override
  Future<void> silentRefresh() async {
    try {
      final next = await _fetch();
      state = AsyncValue.data(next);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
