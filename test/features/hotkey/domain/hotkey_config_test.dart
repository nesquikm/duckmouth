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
