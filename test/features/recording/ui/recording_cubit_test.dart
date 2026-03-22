import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/recording/ui/recording_state.dart';

class MockRecordingRepository extends Mock implements RecordingRepository {}

void main() {
  late MockRecordingRepository mockRepo;

  setUp(() {
    mockRepo = MockRecordingRepository();
    when(() => mockRepo.dispose()).thenAnswer((_) async {});
  });

  group('RecordingCubit', () {
    test('initial state is RecordingIdle', () {
      final cubit = RecordingCubit(repository: mockRepo);
      expect(cubit.state, const RecordingIdle());
      cubit.close();
    });

    group('startRecording', () {
      blocTest<RecordingCubit, RecordingState>(
        'emits [RecordingInProgress] when recording starts successfully',
        setUp: () {
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start()).thenAnswer((_) async {});
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.startRecording(),
        expect: () => [const RecordingInProgress(Duration.zero)],
        verify: (_) {
          verify(() => mockRepo.start()).called(1);
        },
      );

      blocTest<RecordingCubit, RecordingState>(
        'emits duration updates from the repository stream',
        setUp: () {
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start()).thenAnswer((_) async {});
          when(() => mockRepo.durationStream).thenAnswer(
            (_) => Stream.fromIterable([
              const Duration(seconds: 1),
              const Duration(seconds: 2),
            ]),
          );
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) async {
          await cubit.startRecording();
          // Allow stream events to be processed
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const RecordingInProgress(Duration.zero),
          const RecordingInProgress(Duration(seconds: 1)),
          const RecordingInProgress(Duration(seconds: 2)),
        ],
      );

      blocTest<RecordingCubit, RecordingState>(
        'emits [RecordingError] when permission is denied',
        setUp: () {
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => false);
          when(() => mockRepo.requestPermission()).thenAnswer((_) async {});
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.startRecording(),
        expect: () => [
          const RecordingError('Microphone permission denied'),
        ],
      );

      blocTest<RecordingCubit, RecordingState>(
        'requests permission if not already granted and succeeds',
        setUp: () {
          var callCount = 0;
          when(() => mockRepo.hasPermission()).thenAnswer((_) async {
            callCount++;
            return callCount > 1; // false first, true after request
          });
          when(() => mockRepo.requestPermission()).thenAnswer((_) async {});
          when(() => mockRepo.start()).thenAnswer((_) async {});
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.startRecording(),
        expect: () => [const RecordingInProgress(Duration.zero)],
        verify: (_) {
          verify(() => mockRepo.requestPermission()).called(1);
        },
      );

      blocTest<RecordingCubit, RecordingState>(
        'emits [RecordingError] when start throws',
        setUp: () {
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start())
              .thenThrow(Exception('Audio device busy'));
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.startRecording(),
        expect: () => [
          const RecordingError(
            'Failed to start recording: Exception: Audio device busy',
          ),
        ],
      );
    });

    group('stopRecording', () {
      blocTest<RecordingCubit, RecordingState>(
        'emits [RecordingComplete] when recording stops with file path',
        setUp: () {
          when(() => mockRepo.stop())
              .thenAnswer((_) async => '/tmp/recording.m4a');
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.stopRecording(),
        expect: () => [const RecordingComplete('/tmp/recording.m4a')],
      );

      blocTest<RecordingCubit, RecordingState>(
        'emits [RecordingError] when stop returns null',
        setUp: () {
          when(() => mockRepo.stop()).thenAnswer((_) async => null);
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.stopRecording(),
        expect: () => [
          const RecordingError('No recording data available'),
        ],
      );

      blocTest<RecordingCubit, RecordingState>(
        'emits [RecordingError] when stop throws',
        setUp: () {
          when(() => mockRepo.stop()).thenThrow(Exception('Stop failed'));
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.stopRecording(),
        expect: () => [
          const RecordingError(
            'Failed to stop recording: Exception: Stop failed',
          ),
        ],
      );
    });
  });
}
