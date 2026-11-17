import 'package:flutter/services.dart';

class RupiahInputFormatter extends TextInputFormatter {
  static int? amount(String value) =>
      int.tryParse(value.replaceAll(RegExp(r'\D'), ''));

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 13) return oldValue;
    if (digits.isEmpty) return const TextEditingValue();
    digits = int.parse(digits).toString();
    final formatted = digits.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
    final caret =
        newValue.selection.extentOffset.clamp(0, newValue.text.length);
    final rightDigits =
        newValue.text.substring(caret).replaceAll(RegExp(r'\D'), '').length;
    var offset = formatted.length;
    var remaining = rightDigits;
    while (offset > 0 && remaining > 0) {
      offset--;
      if (formatted[offset] != '.') remaining--;
    }
    return TextEditingValue(
        text: formatted, selection: TextSelection.collapsed(offset: offset));
  }
}
