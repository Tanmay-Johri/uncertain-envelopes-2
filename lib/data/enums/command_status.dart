/// Processing status of a command row. See PRD §commands.command_status.
enum CommandStatus {
  pending('pending'),
  claimed('claimed'),
  processed('processed'),
  failed('failed'),
  rejected('rejected');

  const CommandStatus(this.wireValue);

  final String wireValue;

  /// Terminal: processed or rejected (after retry exhaustion). `failed` is
  /// explicitly NOT terminal because it may still be retried up to 3 times.
  bool get isTerminal =>
      this == CommandStatus.processed || this == CommandStatus.rejected;

  static String toWire(CommandStatus value) => value.wireValue;

  static CommandStatus fromWire(String value) {
    for (final s in CommandStatus.values) {
      if (s.wireValue == value) return s;
    }
    throw ArgumentError.value(value, 'value', 'Unknown CommandStatus');
  }

  static CommandStatus? tryFromWire(String? value) {
    if (value == null) return null;
    for (final s in CommandStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}
