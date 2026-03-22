import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/core/api/openai_client.dart';
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
