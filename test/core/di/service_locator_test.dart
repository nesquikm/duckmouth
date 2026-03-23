import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/core/api/llm_client.dart';
import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/core/services/sound_service.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_service.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_cubit.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  test('setupServiceLocator completes without error', () async {
    await setupServiceLocator();
    expect(sl, isNotNull);
  });

  test('sl is the GetIt singleton', () {
    expect(sl, same(GetIt.instance));
  });

  test('registers RecordingRepository', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<RecordingRepository>(), isTrue);
  });

  test('registers RecordingCubit', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<RecordingCubit>(), isTrue);
  });

  test('registers OpenAiClient', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<OpenAiClient>(), isTrue);
  });

  test('registers SttRepository', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<SttRepository>(), isTrue);
  });

  test('registers TranscriptionCubit', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<TranscriptionCubit>(), isTrue);
  });

  test('registers SettingsRepository', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<SettingsRepository>(), isTrue);
  });

  test('registers SettingsCubit', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<SettingsCubit>(), isTrue);
  });

  test('registers SharedPreferences', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<SharedPreferences>(), isTrue);
  });


  test('registers LlmClient', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<LlmClient>(), isTrue);
  });

  test('registers PostProcessingRepository', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<PostProcessingRepository>(), isTrue);
  });

  test('registers PostProcessingCubit', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<PostProcessingCubit>(), isTrue);
  });

  test('registers ClipboardService', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<ClipboardService>(), isTrue);
  });

  test('registers HotkeyService', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<HotkeyService>(), isTrue);
  });

  test('registers HotkeyCubit', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<HotkeyCubit>(), isTrue);
  });

  test('registers SoundService', () async {
    await setupServiceLocator();
    expect(sl.isRegistered<SoundService>(), isTrue);
  });

  group('updateOpenAiClient', () {
    test('re-registers OpenAiClient with new config', () async {
      await setupServiceLocator();

      const config = ApiConfig(
        baseUrl: 'https://api.groq.com/openai/v1',
        apiKey: 'test-key',
        model: 'whisper-large-v3-turbo',
        providerName: 'groq',
      );

      updateOpenAiClient(config);

      expect(sl.isRegistered<OpenAiClient>(), isTrue);
      expect(sl.isRegistered<SttRepository>(), isTrue);
    });
  });

  group('updateLlmClient', () {
    test('re-registers LlmClient with new config', () async {
      await setupServiceLocator();

      const config = ApiConfig(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'llm-key',
        model: 'gpt-4o',
        providerName: 'openAi',
      );

      updateLlmClient(config);

      expect(sl.isRegistered<LlmClient>(), isTrue);
      expect(sl.isRegistered<PostProcessingRepository>(), isTrue);
    });
  });
}
