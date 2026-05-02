import 'package:flutter/material.dart';

import 'game_results_screen.dart';
import 'results_mock_data.dart';
import 'results_view_data.dart';

/// Holds mutable mock “server” envelope state for **`/game/:id/results`**.
class GameResultsMockRouteHost extends StatefulWidget {
  const GameResultsMockRouteHost({
    super.key,
    required this.gameId,
    this.simulateStalePoll = false,
    this.onEndGame,
  });

  final String gameId;

  /// When true, submit succeeds without updating [_data] so reconcile reverts.
  final bool simulateStalePoll;

  final void Function({required bool discardBecauseNoPrice})? onEndGame;

  @override
  State<GameResultsMockRouteHost> createState() =>
      _GameResultsMockRouteHostState();
}

class _GameResultsMockRouteHostState extends State<GameResultsMockRouteHost> {
  late GameResultsViewData _data;

  @override
  void initState() {
    super.initState();
    _data = mockGameResultsViewDataForGameId(widget.gameId);
  }

  Future<void> _onUpdateEnvelopePrice(double? envelopePriceUsd) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (!mounted) return;
    if (widget.simulateStalePoll) return;
    setState(() {
      _data = _data.withEnvelopeUsd(envelopePriceUsd);
    });
  }

  Future<double?> _pollCommittedEnvelope() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return _data.envelopePriceUsd;
  }

  void _endGameCommitted({required bool discardBecauseNoPrice}) {
    widget.onEndGame?.call(discardBecauseNoPrice: discardBecauseNoPrice);
    setState(() {
      _data = _data.withGameEnded(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameResultsScreen(
      gameId: widget.gameId,
      data: _data,
      onUpdateEnvelopePrice:
          _data.isViewerAdmin ? _onUpdateEnvelopePrice : null,
      pollCommittedEnvelopePrice:
          _data.isViewerAdmin ? _pollCommittedEnvelope : null,
      onEndGame: _endGameCommitted,
    );
  }
}
