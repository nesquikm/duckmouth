import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/services/sound_service.dart';

class MockSoundService extends Mock implements SoundService {}

void main() {
  group('SoundService interface', () {
    late MockSoundService mockService;

    setUp(() {
      mockService = MockSoundService();
    });

    test('playRecordingStart can be called', () async {
      when(() => mockService.playRecordingStart(volume: any(named: 'volume')))
          .thenAnswer((_) async {});

      await mockService.playRecordingStart(volume: 0.8);

      verify(() => mockService.playRecordingStart(volume: 0.8)).called(1);
    });

    test('playRecordingStop can be called', () async {
      when(() => mockService.playRecordingStop(volume: any(named: 'volume')))
          .thenAnswer((_) async {});

      await mockService.playRecordingStop(volume: 0.5);

      verify(() => mockService.playRecordingStop(volume: 0.5)).called(1);
    });

    test('playTranscriptionComplete can be called', () async {
      when(() => mockService.playTranscriptionComplete(
            volume: any(named: 'volume'),
          )).thenAnswer((_) async {});

      await mockService.playTranscriptionComplete(volume: 1.0);

      verify(() => mockService.playTranscriptionComplete(volume: 1.0))
          .called(1);
    });

    test('dispose can be called', () {
      when(() => mockService.dispose()).thenReturn(null);

      mockService.dispose();

      verify(() => mockService.dispose()).called(1);
    });
  });

  group('SoundServiceImpl', () {
    test('can be instantiated', () {
      final service = SoundServiceImpl();
      expect(service, isA<SoundService>());
      service.dispose();
    });
  });
}
