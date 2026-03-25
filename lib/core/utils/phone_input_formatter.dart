import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digits.length > 11 ? digits.substring(0, 11) : digits;

    final formatted = _applyMask(truncated);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _applyMask(String digits) {
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();

    // (XX
    buffer.write('(');
    buffer.write(digits.substring(0, digits.length >= 2 ? 2 : digits.length));

    if (digits.length < 3) return buffer.toString();

    // (XX) XXXXX
    buffer.write(') ');
    buffer.write(digits.substring(2, digits.length >= 7 ? 7 : digits.length));

    if (digits.length < 8) return buffer.toString();

    // (XX) XXXXX-XXXX
    buffer.write('-');
    buffer.write(digits.substring(7));

    return buffer.toString();
  }
}
