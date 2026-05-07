import 'package:flutter/services.dart';

/// Normalizes raw quantity text: [double.tryParse], [num.floor], minimum **1**.
/// Non-numeric or empty input becomes **`'1'`**.
String normalizeOrderQtyFieldText(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '1';
  final d = double.tryParse(t);
  if (d == null || d.isNaN || d.isInfinite) return '1';
  final n = d.floor();
  return '${n < 1 ? 1 : n}';
}

/// Quantity for placing an order: floor decimals, require **≥ 1**.
/// Empty or unparseable → `null` (do not submit).
int? parseOrderQtyForSubmit(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final d = double.tryParse(t);
  if (d == null || d.isNaN || d.isInfinite) return null;
  final n = d.floor();
  if (n < 1) return null;
  return n;
}

/// Allows digits and at most one `.` while the user types (then [normalizeOrderQtyFieldText]).
class OrderQtyDecimalTextInputFormatter extends TextInputFormatter {
  const OrderQtyDecimalTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;
    if (!RegExp(r'^[0-9]*\.?[0-9]*$').hasMatch(t)) {
      return oldValue;
    }
    return newValue;
  }
}
