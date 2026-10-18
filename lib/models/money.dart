/// Money helpers. In this app every amount is an `int` number of
/// Colombian pesos (COP has no cents).
///
/// WHY `int` and never `double`: a double cannot store most decimal values
/// exactly (0.1 + 0.2 != 0.3). With integers the split always adds up to
/// the exact total, peso by peso.
library;

/// Formats pesos the Colombian way: `79200` -> `"$ 79.200"`.
String formatPesos(int pesos) {
  final sign = pesos < 0 ? '-' : '';
  final digits = pesos.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    // Put a dot every three digits counting from the right.
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '$sign\$ $buffer';
}

/// [percent] % of [amount], rounded to the nearest peso (half up).
///
/// Adding 50 before dividing by 100 is the integer way of rounding:
/// 10005 * 10 = 100050 -> (100050 + 50) ~/ 100 = 1001.
int percentOf(int amount, int percent) => (amount * percent + 50) ~/ 100;

/// Reads what the user typed as a price: "26000" or "26.000" -> 26000.
/// Returns null when the text is not a whole, non-negative number.
int? parsePesos(String text) {
  final clean = text.trim().replaceAll('.', '');
  if (!RegExp(r'^\d+$').hasMatch(clean)) return null;
  return int.tryParse(clean);
}
