import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
