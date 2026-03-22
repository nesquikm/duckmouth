import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
      'emits [Loading, Error] when transcription fails',
      setUp: () {
        when(() => mockRepo.transcribe(any()))
            .thenThrow(Exception('Network error'));
      },
      build: () => TranscriptionCubit(repository: mockRepo),
      act: (cubit) => cubit.transcribe('/audio.m4a'),
      expect: () => [
        const TranscriptionLoading(),
        const TranscriptionError('Exception: Network error'),
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
  });
}
