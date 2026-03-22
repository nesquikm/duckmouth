import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_state.dart';

void main() {
  const config = HotkeyConfig(
    keyCode: 0x00000020,
    modifiers: ['control', 'shift'],
    mode: HotkeyMode.toggle,
  );

  group('HotkeyState equality', () {
    test('HotkeyIdle instances are equal', () {
      expect(const HotkeyIdle(), equals(const HotkeyIdle()));
    });

    test('HotkeyRegistered with same config are equal', () {
      expect(
        const HotkeyRegistered(config: config),
        equals(const HotkeyRegistered(config: config)),
      );
    });

    test('HotkeyActionStart with same config are equal', () {
      expect(
        const HotkeyActionStart(config: config),
        equals(const HotkeyActionStart(config: config)),
      );
    });

    test('HotkeyActionStop with same config are equal', () {
      expect(
        const HotkeyActionStop(config: config),
        equals(const HotkeyActionStop(config: config)),
      );
    });

    test('HotkeyError with same message are equal', () {
      expect(
        const HotkeyError(message: 'fail'),
        equals(const HotkeyError(message: 'fail')),
      );
    });

    test('HotkeyError with different messages are not equal', () {
      expect(
        const HotkeyError(message: 'fail'),
        isNot(equals(const HotkeyError(message: 'other'))),
      );
    });

    test('different state types are not equal', () {
      expect(const HotkeyIdle(), isNot(equals(const HotkeyRegistered(config: config))));
    });
  });
}
