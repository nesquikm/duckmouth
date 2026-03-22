import 'package:get_it/get_it.dart';

import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/features/recording/data/recording_repository_impl.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/transcription/data/stt_repository_impl.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Recording
  sl.registerLazySingleton<RecordingRepository>(
    RecordingRepositoryImpl.new,
  );

  sl.registerFactory<RecordingCubit>(
    () => RecordingCubit(repository: sl<RecordingRepository>()),
  );

  // OpenAI client
  sl.registerLazySingleton<OpenAiClient>(
    () => OpenAiClientImpl(
      apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
    ),
  );

  // Transcription
  sl.registerLazySingleton<SttRepository>(
    () => SttRepositoryImpl(client: sl<OpenAiClient>()),
  );

  sl.registerFactory<TranscriptionCubit>(
    () => TranscriptionCubit(repository: sl<SttRepository>()),
  );
}
