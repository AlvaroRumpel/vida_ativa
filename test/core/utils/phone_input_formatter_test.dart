import 'package:flutter_test/flutter_test.dart';
import 'package:vida_ativa/core/utils/phone_input_formatter.dart';

String _format(String input) {
  final result = PhoneInputFormatter().formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: input),
  );
  return result.text;
}

void main() {
  group('PhoneInputFormatter._applyMask', () {
    test('empty input returns empty string', () {
      expect(_format(''), '');
    });

    test('1 digit → (X', () {
      expect(_format('1'), '(1');
    });

    test('2 digits → (XX', () {
      expect(_format('11'), '(11');
    });

    test('3 digits → (XX) X', () {
      expect(_format('119'), '(11) 9');
    });

    test('7 digits → (XX) XXXXX', () {
      expect(_format('1191234'), '(11) 91234');
    });

    test('8 digits → (XX) XXXXX-X', () {
      expect(_format('11912345'), '(11) 91234-5');
    });

    test('11 digits → full (XX) XXXXX-XXXX', () {
      expect(_format('11912345678'), '(11) 91234-5678');
    });

    test('12+ digits → truncated to 11, same result as 11', () {
      expect(_format('119123456789'), '(11) 91234-5678');
    });

    test('non-digit chars stripped before masking', () {
      expect(_format('(11) 91234-5678'), '(11) 91234-5678');
    });
  });

  group('PhoneInputFormatter cursor position', () {
    test('cursor placed at end of formatted text', () {
      final formatter = PhoneInputFormatter();
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '11912345678'),
      );
      expect(result.selection.baseOffset, result.text.length);
    });
  });
}
