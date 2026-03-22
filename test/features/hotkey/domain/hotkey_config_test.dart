import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';

void main() {
  group('HotkeyConfig', () {
    test('defaultConfig has expected values', () {
      const config = HotkeyConfig.defaultConfig;
      expect(config.keyCode, 0x0007002C);
      expect(config.modifiers, ['control', 'shift']);
      expect(config.mode, HotkeyMode.toggle);
    });

    test('toHotKey creates HotKey with correct scope', () {
      const config = HotkeyConfig(
        keyCode: 0x0007002C,
        modifiers: ['control', 'shift'],
      );
      final hotKey = config.toHotKey();
      expect(hotKey.scope, HotKeyScope.system);
    });

    test('toHotKey preserves USB HID code in PhysicalKeyboardKey', () {
      const config = HotkeyConfig(
        keyCode: 0x0007002C, // Space USB HID
        modifiers: ['control'],
      );
      final hotKey = config.toHotKey();
      // The PhysicalKeyboardKey stores the USB HID code;
      // uni_platform converts to Carbon automatically during registration.
      expect(hotKey.physicalKey.usbHidUsage, 0x0007002C);
    });

    test('toHotKey preserves unknown USB HID code', () {
      const config = HotkeyConfig(
        keyCode: 0xDEADBEEF,
        modifiers: ['control'],
      );
      final hotKey = config.toHotKey();
      expect(hotKey.physicalKey.usbHidUsage, 0xDEADBEEF);
    });

    test('fromHotKey creates config preserving mode', () {
      final hotKey = HotKey(
        key: PhysicalKeyboardKey(0x00070004),
        modifiers: [HotKeyModifier.alt],
        scope: HotKeyScope.system,
      );

      final config = HotkeyConfig.fromHotKey(
        hotKey,
        mode: HotkeyMode.pushToTalk,
      );

      expect(config.keyCode, 0x00070004);
      expect(config.modifiers, ['alt']);
      expect(config.mode, HotkeyMode.pushToTalk);
    });

    test('displayLabel shows human-readable format for default config', () {
      const config = HotkeyConfig.defaultConfig;
      expect(config.displayLabel, 'Ctrl + Shift + Space');
    });

    test('displayLabel shows letter key correctly', () {
      const config = HotkeyConfig(
        keyCode: 0x00070004, // A
        modifiers: ['meta'],
      );
      expect(config.displayLabel, 'Cmd + A');
    });

    test('displayLabel shows multiple modifiers correctly', () {
      const config = HotkeyConfig(
        keyCode: 0x0007000e, // K
        modifiers: ['control', 'alt', 'shift'],
      );
      expect(config.displayLabel, 'Ctrl + Alt + Shift + K');
    });

    test('displayLabel shows hex for unknown key code', () {
      const config = HotkeyConfig(
        keyCode: 0xDEADBEEF,
        modifiers: ['control'],
      );
      expect(config.displayLabel, contains('Key('));
    });

    test('equality works correctly', () {
      const a = HotkeyConfig(
        keyCode: 0x0007002C,
        modifiers: ['control', 'shift'],
        mode: HotkeyMode.toggle,
      );
      const b = HotkeyConfig(
        keyCode: 0x0007002C,
        modifiers: ['control', 'shift'],
        mode: HotkeyMode.toggle,
      );
      const c = HotkeyConfig(
        keyCode: 0x0007002C,
        modifiers: ['control'],
        mode: HotkeyMode.toggle,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = HotkeyConfig(
        keyCode: 0x0007002C,
        modifiers: ['control', 'shift'],
        mode: HotkeyMode.toggle,
      );
      const b = HotkeyConfig(
        keyCode: 0x0007002C,
        modifiers: ['control', 'shift'],
        mode: HotkeyMode.toggle,
      );
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('HotkeyMode', () {
    test('label returns correct display text', () {
      expect(HotkeyMode.pushToTalk.label, 'Push-to-Talk');
      expect(HotkeyMode.toggle.label, 'Toggle');
    });
  });
}
