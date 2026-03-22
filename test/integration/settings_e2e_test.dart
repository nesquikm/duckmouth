import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';

import '../../integration_test/helpers/fakes/fake_settings_repository.dart';

void main() {
  group('E2E: Settings round-trip', () {
    test('save and reload all config types', () async {
      final repo = FakeSettingsRepository();

      // Save configs.
      const sttConfig = ApiConfig(
        baseUrl: 'https://custom.api.com',
        apiKey: 'test-key-123',
        model: 'whisper-large',
        providerName: 'custom',
      );
      await repo.saveSttConfig(sttConfig);

      const ppConfig = PostProcessingConfig(
        enabled: true,
        prompt: 'Fix grammar please',
      );
      await repo.savePostProcessingConfig(ppConfig);

      await repo.saveOutputMode(OutputMode.both);

      const hotkeyConfig = HotkeyConfig(
        keyCode: 0x00070004, // A
        modifiers: ['meta', 'shift'],
        mode: HotkeyMode.pushToTalk,
      );
      await repo.saveHotkeyConfig(hotkeyConfig);

      const soundConfig = SoundConfig(
        enabled: false,
        startVolume: 0.5,
        stopVolume: 0.7,
        completeVolume: 0.3,
      );
      await repo.saveSoundConfig(soundConfig);

      const audioConfig = AudioFormatConfig(
        preset: QualityPreset.balanced,
      );
      await repo.saveAudioFormatConfig(audioConfig);

      await repo.saveSelectedInputDevice('mic-42');

      // Reload and verify.
      expect(await repo.loadSttConfig(), sttConfig);
      expect(await repo.loadPostProcessingConfig(), ppConfig);
      expect(await repo.loadOutputMode(), OutputMode.both);
      expect(await repo.loadHotkeyConfig(), hotkeyConfig);
      expect(await repo.loadSoundConfig(), soundConfig);
      expect(await repo.loadAudioFormatConfig(), audioConfig);
      expect(await repo.loadSelectedInputDevice(), 'mic-42');
    });
  });
}
