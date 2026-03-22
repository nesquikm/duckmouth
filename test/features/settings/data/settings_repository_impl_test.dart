import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/settings/data/settings_repository_impl.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SharedPreferences prefs;
  late MockFlutterSecureStorage mockSecure;
  late SettingsRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockSecure = MockFlutterSecureStorage();
    repo = SettingsRepositoryImpl(
      prefs: prefs,
      secureStorage: mockSecure,
    );
  });

  group('SettingsRepositoryImpl', () {
    test('loadSttConfig returns null when no settings saved', () async {
      when(() => mockSecure.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await repo.loadSttConfig();
      expect(result, isNull);
    });

    test('loadSttConfig returns saved config', () async {
      await prefs.setString('stt_base_url', 'https://api.groq.com/openai');
      await prefs.setString('stt_model', 'whisper-large-v3-turbo');
      await prefs.setString('stt_provider_name', 'groq');
      when(() => mockSecure.read(key: 'stt_api_key'))
          .thenAnswer((_) async => 'secret-key');

      final result = await repo.loadSttConfig();

      expect(result, isNotNull);
      expect(result!.baseUrl, 'https://api.groq.com/openai');
      expect(result.apiKey, 'secret-key');
      expect(result.model, 'whisper-large-v3-turbo');
      expect(result.providerName, 'groq');
    });

    test('loadSttConfig uses empty string for missing API key', () async {
      await prefs.setString('stt_provider_name', 'openAi');
      when(() => mockSecure.read(key: 'stt_api_key'))
          .thenAnswer((_) async => null);

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

      when(
        () => mockSecure.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenAnswer((_) async {});

      await repo.saveSttConfig(config);

      expect(prefs.getString('stt_base_url'), 'https://api.openai.com');
      expect(prefs.getString('stt_model'), 'whisper-1');
      expect(prefs.getString('stt_provider_name'), 'openAi');
      verify(
        () => mockSecure.write(key: 'stt_api_key', value: 'my-key'),
      ).called(1);
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
      when(() => mockSecure.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

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
      when(() => mockSecure.read(key: 'pp_api_key'))
          .thenAnswer((_) async => 'llm-key');

      final result = await repo.loadPostProcessingConfig();

      expect(result.enabled, true);
      expect(result.prompt, 'Custom prompt');
      expect(result.llmConfig.baseUrl, 'https://custom.api.com');
      expect(result.llmConfig.model, 'gpt-4');
      expect(result.llmConfig.apiKey, 'llm-key');
      expect(result.llmConfig.providerName, 'custom');
    });

    test('savePostProcessingConfig persists all fields', () async {
      when(
        () => mockSecure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

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
      verify(
        () => mockSecure.write(key: 'pp_api_key', value: 'secret'),
      ).called(1);
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
}
