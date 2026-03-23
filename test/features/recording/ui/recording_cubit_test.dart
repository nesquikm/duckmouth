import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/recording/ui/recording_state.dart';

class MockRecordingRepository extends Mock implements RecordingRepository {}

void main() {
  late MockRecordingRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(const AudioFormatConfig());
  });

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
          when(() => mockRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).thenAnswer((_) async {});
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) => cubit.startRecording(),
        expect: () => [const RecordingInProgress(Duration.zero)],
        verify: (_) {
          verify(() => mockRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).called(1);
        },
      );

      blocTest<RecordingCubit, RecordingState>(
        'emits duration updates from the repository stream',
        setUp: () {
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).thenAnswer((_) async {});
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
          const RecordingError(
            'Microphone access required. Open System Settings > '
            'Privacy & Security > Microphone and enable access '
            'for Duckmouth.',
          ),
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
          when(() => mockRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId'))).thenAnswer((_) async {});
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
          when(() => mockRepo.start(formatConfig: any(named: 'formatConfig'), deviceId: any(named: 'deviceId')))
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

    group('rapid press race condition', () {
      blocTest<RecordingCubit, RecordingState>(
        'stop during start sets pending flag and auto-stops after start completes',
        setUp: () {
          final startCompleter = Completer<void>();
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start(
                formatConfig: any(named: 'formatConfig'),
                deviceId: any(named: 'deviceId'),
              )).thenAnswer((_) => startCompleter.future);
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
          when(() => mockRepo.stop())
              .thenAnswer((_) async => '/tmp/recording.m4a');
          // Complete start after a microtask to allow stop to be called first
          Future<void>.delayed(const Duration(milliseconds: 50), () {
            startCompleter.complete();
          });
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) async {
          // Start recording (will be delayed by completer)
          final startFuture = cubit.startRecording();
          // Immediately try to stop — start hasn't completed yet
          await cubit.stopRecording();
          // Wait for start to finish
          await startFuture;
          // Allow pending stop to process
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const RecordingInProgress(Duration.zero),
          const RecordingComplete('/tmp/recording.m4a'),
        ],
        verify: (_) {
          verify(() => mockRepo.stop()).called(1);
        },
      );

      blocTest<RecordingCubit, RecordingState>(
        'normal start/stop flow is unaffected',
        setUp: () {
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start(
                formatConfig: any(named: 'formatConfig'),
                deviceId: any(named: 'deviceId'),
              )).thenAnswer((_) async {});
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
          when(() => mockRepo.stop())
              .thenAnswer((_) async => '/tmp/recording.m4a');
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) async {
          await cubit.startRecording();
          await cubit.stopRecording();
        },
        expect: () => [
          const RecordingInProgress(Duration.zero),
          const RecordingComplete('/tmp/recording.m4a'),
        ],
      );

      blocTest<RecordingCubit, RecordingState>(
        'pendingStop is reset on new startRecording call',
        setUp: () {
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start(
                formatConfig: any(named: 'formatConfig'),
                deviceId: any(named: 'deviceId'),
              )).thenAnswer((_) async {});
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
          when(() => mockRepo.stop())
              .thenAnswer((_) async => '/tmp/recording.m4a');
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) async {
          // First start/stop cycle
          await cubit.startRecording();
          await cubit.stopRecording();
          // Second start — should work normally without auto-stop
          await cubit.startRecording();
        },
        expect: () => [
          const RecordingInProgress(Duration.zero),
          const RecordingComplete('/tmp/recording.m4a'),
          const RecordingInProgress(Duration.zero),
        ],
      );

      blocTest<RecordingCubit, RecordingState>(
        'toggle mode rapid double-tap stops cleanly',
        setUp: () {
          final startCompleter = Completer<void>();
          when(() => mockRepo.hasPermission())
              .thenAnswer((_) async => true);
          when(() => mockRepo.start(
                formatConfig: any(named: 'formatConfig'),
                deviceId: any(named: 'deviceId'),
              )).thenAnswer((_) => startCompleter.future);
          when(() => mockRepo.durationStream)
              .thenAnswer((_) => const Stream<Duration>.empty());
          when(() => mockRepo.stop())
              .thenAnswer((_) async => '/tmp/recording.m4a');
          Future<void>.delayed(const Duration(milliseconds: 50), () {
            startCompleter.complete();
          });
        },
        build: () => RecordingCubit(repository: mockRepo),
        act: (cubit) async {
          // Simulate toggle mode: press once (start), press again quickly (stop)
          final startFuture = cubit.startRecording();
          await cubit.stopRecording();
          await startFuture;
          await Future<void>.delayed(Duration.zero);
        },
        expect: () => [
          const RecordingInProgress(Duration.zero),
          const RecordingComplete('/tmp/recording.m4a'),
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
