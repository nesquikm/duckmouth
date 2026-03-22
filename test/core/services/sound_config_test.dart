import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/core/services/sound_config.dart';

void main() {
  group('SoundConfig', () {
    test('default values', () {
      const config = SoundConfig();
      expect(config.enabled, isTrue);
      expect(config.startVolume, 1.0);
      expect(config.stopVolume, 1.0);
      expect(config.completeVolume, 1.0);
    });

    test('copyWith returns updated config', () {
      const config = SoundConfig();
      final updated = config.copyWith(enabled: false, startVolume: 0.5);
      expect(updated.enabled, isFalse);
      expect(updated.startVolume, 0.5);
      expect(updated.stopVolume, 1.0);
      expect(updated.completeVolume, 1.0);
    });

    test('copyWith with no arguments returns equal config', () {
      const config = SoundConfig(
        enabled: false,
        startVolume: 0.3,
        stopVolume: 0.7,
        completeVolume: 0.9,
      );
      expect(config.copyWith(), config);
    });

    test('equality', () {
      const a = SoundConfig(startVolume: 0.5);
      const b = SoundConfig(startVolume: 0.5);
      const c = SoundConfig(startVolume: 0.8);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = SoundConfig(startVolume: 0.5);
      const b = SoundConfig(startVolume: 0.5);
      expect(a.hashCode, b.hashCode);
    });
  });
}
