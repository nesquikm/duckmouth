import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';
import 'package:duckmouth/features/transcription/ui/transcription_state.dart';

class MockSttRepository extends Mock implements SttRepository {}

void main() {
  late MockSttRepository mockRepo;

  setUp(() {
    mockRepo = MockSttRepository();
  });

  group('TranscriptionCubit', () {
    test('initial state is TranscriptionIdle', () {
      final cubit = TranscriptionCubit(repository: mockRepo);
      expect(cubit.state, const TranscriptionIdle());
      cubit.close();
    });

    blocTest<TranscriptionCubit, TranscriptionState>(
      'emits [Loading, Success] when transcription succeeds',
      setUp: () {
        when(() => mockRepo.transcribe(any()))
            .thenAnswer((_) async => 'Hello world');
      },
      build: () => TranscriptionCubit(repository: mockRepo),
      act: (cubit) => cubit.transcribe('/audio.m4a'),
      expect: () => [
        const TranscriptionLoading(),
        const TranscriptionSuccess('Hello world'),
      ],
      verify: (_) {
        verify(() => mockRepo.transcribe('/audio.m4a')).called(1);
      },
    );

    blocTest<TranscriptionCubit, TranscriptionState>(
      'emits [Loading, Error] with friendly message on generic exception',
      setUp: () {
        when(() => mockRepo.transcribe(any()))
            .thenThrow(Exception('something went wrong'));
      },
      build: () => TranscriptionCubit(repository: mockRepo),
      act: (cubit) => cubit.transcribe('/audio.m4a'),
      expect: () => [
        const TranscriptionLoading(),
        const TranscriptionError('Transcription failed. Please try again.'),
      ],
    );

    blocTest<TranscriptionCubit, TranscriptionState>(
      'emits [Loading, Error] with API message on OpenAiClientException',
      setUp: () {
        when(() => mockRepo.transcribe(any()))
            .thenThrow(const OpenAiClientException(
          'Invalid API key. Check your API key in Settings.',
          statusCode: 401,
        ));
      },
      build: () => TranscriptionCubit(repository: mockRepo),
      act: (cubit) => cubit.transcribe('/audio.m4a'),
      expect: () => [
        const TranscriptionLoading(),
        const TranscriptionError(
          'Invalid API key. Check your API key in Settings.',
        ),
      ],
    );

    blocTest<TranscriptionCubit, TranscriptionState>(
      'emits [Loading, Error] with network message on SocketException',
      setUp: () {
        when(() => mockRepo.transcribe(any()))
            .thenThrow(const SocketException('No internet'));
      },
      build: () => TranscriptionCubit(repository: mockRepo),
      act: (cubit) => cubit.transcribe('/audio.m4a'),
      expect: () => [
        const TranscriptionLoading(),
        const TranscriptionError(
          'Network error. Check your internet connection and try again.',
        ),
      ],
    );

    blocTest<TranscriptionCubit, TranscriptionState>(
      'emits [Loading, Error] when transcription result is empty',
      setUp: () {
        when(() => mockRepo.transcribe(any()))
            .thenAnswer((_) async => '   ');
      },
      build: () => TranscriptionCubit(repository: mockRepo),
      act: (cubit) => cubit.transcribe('/audio.m4a'),
      expect: () => [
        const TranscriptionLoading(),
        const TranscriptionError(
          'No speech detected. Try speaking louder or check your microphone.',
        ),
      ],
    );

    blocTest<TranscriptionCubit, TranscriptionState>(
      'emits [Loading, Success] on subsequent calls',
      setUp: () {
        when(() => mockRepo.transcribe(any()))
            .thenAnswer((_) async => 'Second transcription');
      },
      build: () => TranscriptionCubit(repository: mockRepo),
      seed: () => const TranscriptionSuccess('First'),
      act: (cubit) => cubit.transcribe('/audio2.m4a'),
      expect: () => [
        const TranscriptionLoading(),
        const TranscriptionSuccess('Second transcription'),
      ],
    );

    blocTest<TranscriptionCubit, TranscriptionState>(
      'reset emits TranscriptionIdle',
      build: () => TranscriptionCubit(repository: mockRepo),
      seed: () => const TranscriptionSuccess('some text'),
      act: (cubit) => cubit.reset(),
      expect: () => [const TranscriptionIdle()],
    );
  });
}
