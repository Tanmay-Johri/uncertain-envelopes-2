import 'package:freezed_annotation/freezed_annotation.dart';

part 'execution.freezed.dart';
part 'execution.g.dart';

/// Mirror of the `executions` table. See PRD §executions.
///
/// `executionPrice` equals the price of the matched *resting* order, per the
/// PRD matching rules. All executions belong to a single game.
@freezed
class Execution with _$Execution {
  const factory Execution({
    @JsonKey(name: 'executions_id') required String executionsId,
    @JsonKey(name: 'executions_game_id') required String executionsGameId,
    @JsonKey(name: 'buy_order_id') required String buyOrderId,
    @JsonKey(name: 'sell_order_id') required String sellOrderId,
    @JsonKey(name: 'quantity') required int quantity,
    @JsonKey(name: 'execution_price') required double executionPrice,
    @JsonKey(name: 'executed_at') required DateTime executedAt,
  }) = _Execution;

  factory Execution.fromJson(Map<String, dynamic> json) =>
      _$ExecutionFromJson(json);
}
