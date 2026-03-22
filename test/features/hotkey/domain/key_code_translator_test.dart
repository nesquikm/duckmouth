import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/hotkey/domain/key_code_translator.dart';

void main() {
  group('KeyCodeTranslator', () {
    group('usbHidToCarbon', () {
      test('Space (0x0007002C) maps to Carbon 49', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x0007002C), 49);
      });

      test('A (0x00070004) maps to Carbon 0', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x00070004), 0);
      });

      test('S (0x00070016) maps to Carbon 1', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x00070016), 1);
      });

      test('Z (0x0007001D) maps to Carbon 6', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x0007001D), 6);
      });

      test('Return (0x00070028) maps to Carbon 36', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x00070028), 36);
      });

      test('Escape (0x00070029) maps to Carbon 53', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x00070029), 53);
      });

      test('Tab (0x0007002B) maps to Carbon 48', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x0007002B), 48);
      });

      test('F1 (0x0007003A) maps to Carbon 122', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x0007003A), 122);
      });

      test('F12 (0x00070045) maps to Carbon 111', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x00070045), 111);
      });

      test('1 (0x0007001E) maps to Carbon 18', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x0007001E), 18);
      });

      test('0 (0x00070027) maps to Carbon 29', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x00070027), 29);
      });

      test('Right arrow maps to Carbon 124', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x0007004F), 124);
      });

      test('Left arrow maps to Carbon 123', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0x00070050), 123);
      });

      test('unknown USB HID code returns null', () {
        expect(KeyCodeTranslator.usbHidToCarbon(0xDEADBEEF), isNull);
      });

      test('all letters A-Z have mappings', () {
        for (var i = 0x00070004; i <= 0x0007001D; i++) {
          expect(
            KeyCodeTranslator.usbHidToCarbon(i),
            isNotNull,
            reason: 'Missing Carbon mapping for USB HID 0x${i.toRadixString(16)}',
          );
        }
      });

      test('all numbers 1-0 have mappings', () {
        for (var i = 0x0007001E; i <= 0x00070027; i++) {
          expect(
            KeyCodeTranslator.usbHidToCarbon(i),
            isNotNull,
            reason: 'Missing Carbon mapping for USB HID 0x${i.toRadixString(16)}',
          );
        }
      });

      test('all function keys F1-F12 have mappings', () {
        for (var i = 0x0007003A; i <= 0x00070045; i++) {
          expect(
            KeyCodeTranslator.usbHidToCarbon(i),
            isNotNull,
            reason: 'Missing Carbon mapping for USB HID 0x${i.toRadixString(16)}',
          );
        }
      });
    });

    group('usbHidToLabel', () {
      test('Space returns "Space"', () {
        expect(KeyCodeTranslator.usbHidToLabel(0x0007002C), 'Space');
      });

      test('A returns "A"', () {
        expect(KeyCodeTranslator.usbHidToLabel(0x00070004), 'A');
      });

      test('F1 returns "F1"', () {
        expect(KeyCodeTranslator.usbHidToLabel(0x0007003A), 'F1');
      });

      test('1 returns "1"', () {
        expect(KeyCodeTranslator.usbHidToLabel(0x0007001E), '1');
      });

      test('Return returns "Return"', () {
        expect(KeyCodeTranslator.usbHidToLabel(0x00070028), 'Return');
      });

      test('unknown code returns formatted hex', () {
        final label = KeyCodeTranslator.usbHidToLabel(0xDEADBEEF);
        expect(label, contains('0x'));
        expect(label, startsWith('Key('));
      });

      test('all mapped keys have labels', () {
        for (final code in KeyCodeTranslator.supportedUsbHidCodes) {
          final label = KeyCodeTranslator.usbHidToLabel(code);
          expect(
            label,
            isNot(startsWith('Key(')),
            reason: 'USB HID 0x${code.toRadixString(16)} has Carbon mapping but no label',
          );
        }
      });
    });
  });
}
