import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/core/api/llm_client.dart';
import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/core/services/sound_service.dart';
import 'package:duckmouth/features/hotkey/data/hotkey_service_impl.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_service.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_cubit.dart';
import 'package:duckmouth/features/post_processing/data/post_processing_repository_impl.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/recording/data/recording_repository_impl.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/settings/data/settings_repository_impl.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/transcription/data/stt_repository_impl.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Storage
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // Clipboard
  sl.registerLazySingleton<ClipboardService>(ClipboardServiceImpl.new);

  // Sound
  sl.registerLazySingleton<SoundService>(SoundServiceImpl.new);

  // Settings
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      prefs: sl<SharedPreferences>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(repository: sl<SettingsRepository>()),
  );

  // Recording
  sl.registerLazySingleton<RecordingRepository>(
    RecordingRepositoryImpl.new,
  );

  sl.registerFactory<RecordingCubit>(
    () => RecordingCubit(repository: sl<RecordingRepository>()),
  );

  // OpenAI client — reads current settings each time it's resolved.
  sl.registerFactory<OpenAiClient>(
    () => OpenAiClientImpl(
      apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
    ),
  );

  // Transcription
  sl.registerFactory<SttRepository>(
    () => SttRepositoryImpl(client: sl<OpenAiClient>()),
  );

  sl.registerFactory<TranscriptionCubit>(
    () => TranscriptionCubit(repository: sl<SttRepository>()),
  );

  // LLM client — default (re-registered when settings change).
  sl.registerFactory<LlmClient>(
    () => LlmClientImpl(
      apiKey: '',
      baseUrl: 'https://api.openai.com',
      model: 'gpt-4o-mini',
    ),
  );

  // Hotkey
  sl.registerLazySingleton<HotkeyService>(HotkeyServiceImpl.new);

  sl.registerFactory<HotkeyCubit>(
    () => HotkeyCubit(service: sl<HotkeyService>()),
  );

  // Post-processing
  sl.registerFactory<PostProcessingRepository>(
    () => PostProcessingRepositoryImpl(client: sl<LlmClient>()),
  );

  sl.registerFactory<PostProcessingCubit>(
    () => PostProcessingCubit(
      repository: sl<PostProcessingRepository>(),
      config: const PostProcessingConfig(),
    ),
  );
}

/// Re-register the [OpenAiClient] with the given [config].
///
/// Also re-registers [SttRepository] so it picks up the new client.
void updateOpenAiClient(ApiConfig config) {
  if (sl.isRegistered<OpenAiClient>()) {
    sl.unregister<OpenAiClient>();
  }
  sl.registerFactory<OpenAiClient>(
    () => OpenAiClientImpl(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      model: config.model,
    ),
  );

  if (sl.isRegistered<SttRepository>()) {
    sl.unregister<SttRepository>();
  }
  sl.registerFactory<SttRepository>(
    () => SttRepositoryImpl(client: sl<OpenAiClient>()),
  );
}

/// Re-register the [LlmClient] with the given [config].
///
/// Also re-registers [PostProcessingRepository] so it picks up the new client.
void updateLlmClient(ApiConfig config) {
  if (sl.isRegistered<LlmClient>()) {
    sl.unregister<LlmClient>();
  }
  sl.registerFactory<LlmClient>(
    () => LlmClientImpl(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      model: config.model,
    ),
  );

  if (sl.isRegistered<PostProcessingRepository>()) {
    sl.unregister<PostProcessingRepository>();
  }
  sl.registerFactory<PostProcessingRepository>(
    () => PostProcessingRepositoryImpl(client: sl<LlmClient>()),
  );
}
