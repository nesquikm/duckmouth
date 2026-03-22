import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

import 'package:duckmouth/features/recording/data/recording_repository_impl.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';

class MockAudioRecorder extends Mock implements AudioRecorder {}

class FakeRecordConfig extends Fake implements RecordConfig {}

void main() {
  late MockAudioRecorder mockRecorder;
  late RecordingRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(FakeRecordConfig());
  });

  setUp(() {
    mockRecorder = MockAudioRecorder();
    repo = RecordingRepositoryImpl(recorder: mockRecorder);
  });

  tearDown(() async {
    // Avoid timer leaks by cancelling duration stream controller
    when(() => mockRecorder.dispose()).thenAnswer((_) async {});
    await repo.dispose();
  });

  group('RecordingRepositoryImpl.start', () {
    test('with default config uses WAV encoder', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(
        () => mockRecorder.start(any(), path: any(named: 'path')),
      ).thenAnswer((_) async {});

      await repo.start();

      final captured = verify(
        () => mockRecorder.start(
          captureAny(),
          path: captureAny(named: 'path'),
        ),
      ).captured;

      final recordConfig = captured[0] as RecordConfig;
      final path = captured[1] as String;

      expect(recordConfig.encoder, AudioEncoder.wav);
      expect(recordConfig.sampleRate, 16000);
      expect(recordConfig.numChannels, 1);
      expect(path, endsWith('.wav'));
    });

    test('with AAC preset uses AAC encoder', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(
        () => mockRecorder.start(any(), path: any(named: 'path')),
      ).thenAnswer((_) async {});

      const config = AudioFormatConfig(preset: QualityPreset.balanced);
      await repo.start(formatConfig: config);

      final captured = verify(
        () => mockRecorder.start(
          captureAny(),
          path: captureAny(named: 'path'),
        ),
      ).captured;

      final recordConfig = captured[0] as RecordConfig;
      final path = captured[1] as String;

      expect(recordConfig.encoder, AudioEncoder.aacLc);
      expect(recordConfig.sampleRate, 16000);
      expect(recordConfig.bitRate, 64000);
      expect(path, endsWith('.m4a'));
    });

    test('with custom config uses specified format', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(
        () => mockRecorder.start(any(), path: any(named: 'path')),
      ).thenAnswer((_) async {});

      const config = AudioFormatConfig(
        preset: QualityPreset.custom,
        format: AudioFormat.opus,
        sampleRate: 48000,
        bitRate: 96000,
      );
      await repo.start(formatConfig: config);

      final captured = verify(
        () => mockRecorder.start(
          captureAny(),
          path: captureAny(named: 'path'),
        ),
      ).captured;

      final recordConfig = captured[0] as RecordConfig;
      final path = captured[1] as String;

      expect(recordConfig.encoder, AudioEncoder.opus);
      expect(recordConfig.sampleRate, 48000);
      expect(recordConfig.bitRate, 96000);
      expect(path, endsWith('.ogg'));
    });

    test('file extension matches format for all presets', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => true);
      when(
        () => mockRecorder.start(any(), path: any(named: 'path')),
      ).thenAnswer((_) async {});

      // Test smallest preset (AAC)
      const smallestConfig = AudioFormatConfig(preset: QualityPreset.smallest);
      await repo.start(formatConfig: smallestConfig);

      final captured = verify(
        () => mockRecorder.start(
          captureAny(),
          path: captureAny(named: 'path'),
        ),
      ).captured;

      final path = captured[1] as String;
      expect(path, endsWith('.m4a'));
    });

    test('throws RecordingPermissionException when no permission', () async {
      when(() => mockRecorder.hasPermission()).thenAnswer((_) async => false);

      expect(
        () => repo.start(),
        throwsA(isA<RecordingPermissionException>()),
      );
    });
  });
}
