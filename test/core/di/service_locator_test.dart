import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

void main() {
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
}
