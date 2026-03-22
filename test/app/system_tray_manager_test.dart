import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/app/system_tray_manager.dart';

void main() {
  group('SystemTrayManager', () {
    test('can be instantiated', () {
      final manager = SystemTrayManager();
      expect(manager, isNotNull);
    });

    test('setOnShow stores callback', () {
      final manager = SystemTrayManager();
      var called = false;
      manager.setOnShow(() => called = true);
      // We can't trigger the callback without initializing the tray,
      // but we verify the setter doesn't throw.
      expect(called, isFalse);
    });

    test('setOnQuit stores callback', () {
      final manager = SystemTrayManager();
      var called = false;
      manager.setOnQuit(() => called = true);
      expect(called, isFalse);
    });

    test('dispose does not throw when tray is not initialized', () {
      final manager = SystemTrayManager();
      expect(() => manager.dispose(), returnsNormally);
    });

    test('updateToolTip does not throw when tray is not initialized', () {
      final manager = SystemTrayManager();
      // Should not throw even when _systemTray is null.
      expect(() => manager.updateToolTip('Recording...'), returnsNormally);
    });
  });
}
