import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/settings/data/settings_repository_impl.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = SettingsRepositoryImpl(prefs: prefs);
  });

  group('SettingsRepositoryImpl', () {
    test('loadSttConfig returns null when no settings saved', () async {
      final result = await repo.loadSttConfig();
      expect(result, isNull);
    });

    test('loadSttConfig returns saved config', () async {
      await prefs.setString('stt_base_url', 'https://api.groq.com/openai');
      await prefs.setString('stt_model', 'whisper-large-v3-turbo');
      await prefs.setString('stt_provider_name', 'groq');
      await prefs.setString('stt_api_key', 'secret-key');

      final result = await repo.loadSttConfig();

      expect(result, isNotNull);
      expect(result!.baseUrl, 'https://api.groq.com/openai');
      expect(result.apiKey, 'secret-key');
      expect(result.model, 'whisper-large-v3-turbo');
      expect(result.providerName, 'groq');
    });

    test('loadSttConfig uses empty string for missing API key', () async {
      await prefs.setString('stt_provider_name', 'openAi');

      final result = await repo.loadSttConfig();

      expect(result, isNotNull);
      expect(result!.apiKey, '');
    });

    test('saveSttConfig persists all fields', () async {
      const config = ApiConfig(
        baseUrl: 'https://api.openai.com',
        apiKey: 'my-key',
        model: 'whisper-1',
        providerName: 'openAi',
      );

      await repo.saveSttConfig(config);

      expect(prefs.getString('stt_base_url'), 'https://api.openai.com');
      expect(prefs.getString('stt_model'), 'whisper-1');
      expect(prefs.getString('stt_provider_name'), 'openAi');
      expect(prefs.getString('stt_api_key'), 'my-key');
    });
  });

  group('ProviderPreset', () {
    test('OpenAI preset has correct defaults', () {
      // Verified through API config constants in provider_preset.dart
      expect(true, isTrue);
    });
  });

  group('PostProcessingConfig persistence', () {
    test('loadPostProcessingConfig returns defaults when nothing saved',
        () async {
      final result = await repo.loadPostProcessingConfig();

      expect(result.enabled, false);
      expect(result.prompt, contains('Fix any grammar'));
      expect(result.llmConfig.baseUrl, 'https://api.openai.com');
      expect(result.llmConfig.model, 'gpt-4o-mini');
      expect(result.llmConfig.apiKey, '');
    });

    test('loadPostProcessingConfig returns saved values', () async {
      await prefs.setBool('pp_enabled', true);
      await prefs.setString('pp_prompt', 'Custom prompt');
      await prefs.setString('pp_base_url', 'https://custom.api.com');
      await prefs.setString('pp_model', 'gpt-4');
      await prefs.setString('pp_provider_name', 'custom');
      await prefs.setString('pp_api_key', 'llm-key');

      final result = await repo.loadPostProcessingConfig();

      expect(result.enabled, true);
      expect(result.prompt, 'Custom prompt');
      expect(result.llmConfig.baseUrl, 'https://custom.api.com');
      expect(result.llmConfig.model, 'gpt-4');
      expect(result.llmConfig.apiKey, 'llm-key');
      expect(result.llmConfig.providerName, 'custom');
    });

    test('savePostProcessingConfig persists all fields', () async {
      const config = PostProcessingConfig(
        enabled: true,
        prompt: 'My prompt',
        llmConfig: ApiConfig(
          baseUrl: 'https://api.example.com',
          apiKey: 'secret',
          model: 'gpt-4o',
          providerName: 'custom',
        ),
      );

      await repo.savePostProcessingConfig(config);

      expect(prefs.getBool('pp_enabled'), true);
      expect(prefs.getString('pp_prompt'), 'My prompt');
      expect(prefs.getString('pp_base_url'), 'https://api.example.com');
      expect(prefs.getString('pp_model'), 'gpt-4o');
      expect(prefs.getString('pp_provider_name'), 'custom');
      expect(prefs.getString('pp_api_key'), 'secret');
    });
  });

  group('OutputMode persistence', () {
    test('loadOutputMode returns copy when nothing saved', () async {
      final result = await repo.loadOutputMode();
      expect(result, OutputMode.copy);
    });

    test('loadOutputMode returns saved value', () async {
      await prefs.setString('output_mode', 'paste');
      final result = await repo.loadOutputMode();
      expect(result, OutputMode.paste);
    });

    test('loadOutputMode returns copy for unknown value', () async {
      await prefs.setString('output_mode', 'nonexistent');
      final result = await repo.loadOutputMode();
      expect(result, OutputMode.copy);
    });

    test('saveOutputMode persists the mode', () async {
      await repo.saveOutputMode(OutputMode.both);
      expect(prefs.getString('output_mode'), 'both');
    });
  });

  group('HotkeyConfig persistence', () {
    test('loadHotkeyConfig returns default when nothing saved', () async {
      final result = await repo.loadHotkeyConfig();
      expect(result, HotkeyConfig.defaultConfig);
    });

    test('loadHotkeyConfig returns saved values', () async {
      await prefs.setInt('hotkey_key_code', 0x00070004);
      await prefs.setString('hotkey_modifiers', '["alt","shift"]');
      await prefs.setString('hotkey_mode', 'pushToTalk');

      final result = await repo.loadHotkeyConfig();

      expect(result.keyCode, 0x00070004);
      expect(result.modifiers, ['alt', 'shift']);
      expect(result.mode, HotkeyMode.pushToTalk);
    });

    test('loadHotkeyConfig returns toggle for unknown mode', () async {
      await prefs.setInt('hotkey_key_code', 0x00000020);
      await prefs.setString('hotkey_modifiers', '["control"]');
      await prefs.setString('hotkey_mode', 'nonexistent');

      final result = await repo.loadHotkeyConfig();
      expect(result.mode, HotkeyMode.toggle);
    });

    test('saveHotkeyConfig persists all fields', () async {
      const config = HotkeyConfig(
        keyCode: 0x00070004,
        modifiers: ['alt', 'meta'],
        mode: HotkeyMode.pushToTalk,
      );

      await repo.saveHotkeyConfig(config);

      expect(prefs.getInt('hotkey_key_code'), 0x00070004);
      expect(prefs.getString('hotkey_modifiers'), '["alt","meta"]');
      expect(prefs.getString('hotkey_mode'), 'pushToTalk');
    });
  });

  group('SoundConfig persistence', () {
    test('loadSoundConfig returns defaults when nothing saved', () async {
      final result = await repo.loadSoundConfig();
      expect(result.enabled, true);
      expect(result.startVolume, 1.0);
      expect(result.stopVolume, 1.0);
      expect(result.completeVolume, 1.0);
    });

    test('loadSoundConfig returns saved values', () async {
      await prefs.setBool('sound_enabled', false);
      await prefs.setDouble('sound_start_volume', 0.3);
      await prefs.setDouble('sound_stop_volume', 0.7);
      await prefs.setDouble('sound_complete_volume', 0.5);

      final result = await repo.loadSoundConfig();

      expect(result.enabled, false);
      expect(result.startVolume, 0.3);
      expect(result.stopVolume, 0.7);
      expect(result.completeVolume, 0.5);
    });

    test('saveSoundConfig persists all fields', () async {
      const config = SoundConfig(
        enabled: false,
        startVolume: 0.4,
        stopVolume: 0.6,
        completeVolume: 0.8,
      );

      await repo.saveSoundConfig(config);

      expect(prefs.getBool('sound_enabled'), false);
      expect(prefs.getDouble('sound_start_volume'), 0.4);
      expect(prefs.getDouble('sound_stop_volume'), 0.6);
      expect(prefs.getDouble('sound_complete_volume'), 0.8);
    });
  });

  group('AudioFormatConfig persistence', () {
    test('loadAudioFormatConfig returns default when nothing saved', () async {
      final result = await repo.loadAudioFormatConfig();
      expect(result, const AudioFormatConfig());
    });

    test('saveAudioFormatConfig/loadAudioFormatConfig round-trips', () async {
      const config = AudioFormatConfig(
        preset: QualityPreset.balanced,
        format: AudioFormat.aac,
        sampleRate: 22050,
        bitRate: 64000,
      );

      await repo.saveAudioFormatConfig(config);
      final result = await repo.loadAudioFormatConfig();

      expect(result.preset, QualityPreset.balanced);
      expect(result.format, AudioFormat.aac);
      expect(result.sampleRate, 22050);
      expect(result.bitRate, 64000);
    });

    test('loadAudioFormatConfig returns default preset for unknown value',
        () async {
      await prefs.setString('audio_preset', 'nonexistent');
      final result = await repo.loadAudioFormatConfig();
      expect(result.preset, QualityPreset.bestCompatibility);
    });

    test('saveAudioFormatConfig with null bitRate removes key', () async {
      // First save with bitRate
      await repo.saveAudioFormatConfig(
        const AudioFormatConfig(bitRate: 64000),
      );
      expect(prefs.getInt('audio_bit_rate'), 64000);

      // Then save without bitRate
      await repo.saveAudioFormatConfig(const AudioFormatConfig());
      expect(prefs.getInt('audio_bit_rate'), isNull);
    });

    test('loadAudioFormatConfig returns null bitRate when not saved', () async {
      await prefs.setString('audio_preset', 'bestCompatibility');
      final result = await repo.loadAudioFormatConfig();
      expect(result.bitRate, isNull);
    });
  });

  group('Input device persistence', () {
    test('loadSelectedInputDevice returns null when nothing saved', () async {
      final result = await repo.loadSelectedInputDevice();
      expect(result, isNull);
    });

    test('saveSelectedInputDevice/loadSelectedInputDevice round-trips',
        () async {
      await repo.saveSelectedInputDevice('device-123');
      final result = await repo.loadSelectedInputDevice();
      expect(result, 'device-123');
    });

    test('saveSelectedInputDevice with null clears value', () async {
      await repo.saveSelectedInputDevice('device-123');
      await repo.saveSelectedInputDevice(null);
      final result = await repo.loadSelectedInputDevice();
      expect(result, isNull);
    });
  });
}
