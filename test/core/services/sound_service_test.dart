import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/services/sound_service.dart';

class MockSoundService extends Mock implements SoundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.duckmouth/sound');

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
    late SoundServiceImpl service;
    late List<MethodCall> log;

    setUp(() {
      log = [];
      service = SoundServiceImpl();
    });

    void setUpMockChannel(
      TestWidgetsFlutterBinding binding, {
      Map<String, dynamic>? result,
    }) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          log.add(call);
          return result ?? {'success': true};
        },
      );
    }

    testWidgets('playRecordingStart sends Tink with volume',
        (tester) async {
      setUpMockChannel(tester.binding);

      await service.playRecordingStart(volume: 0.7);

      expect(log.length, 1);
      expect(log.first.method, 'playSound');
      final args = log.first.arguments as Map;
      expect(args['name'], 'Tink');
      expect(args['volume'], 0.7);
    });

    testWidgets('playRecordingStop sends Pop with volume',
        (tester) async {
      setUpMockChannel(tester.binding);

      await service.playRecordingStop(volume: 0.5);

      expect(log.length, 1);
      final args = log.first.arguments as Map;
      expect(args['name'], 'Pop');
      expect(args['volume'], 0.5);
    });

    testWidgets('playTranscriptionComplete sends Glass with volume',
        (tester) async {
      setUpMockChannel(tester.binding);

      await service.playTranscriptionComplete(volume: 0.3);

      expect(log.length, 1);
      final args = log.first.arguments as Map;
      expect(args['name'], 'Glass');
      expect(args['volume'], 0.3);
    });

    testWidgets('volume is clamped to 0.0-1.0', (tester) async {
      setUpMockChannel(tester.binding);

      await service.playRecordingStart(volume: 2.5);

      final args = log.first.arguments as Map;
      expect(args['volume'], 1.0);
    });

    testWidgets('negative volume is clamped to 0.0', (tester) async {
      setUpMockChannel(tester.binding);

      await service.playRecordingStart(volume: -0.5);

      final args = log.first.arguments as Map;
      expect(args['volume'], 0.0);
    });

    testWidgets('default volume is 1.0', (tester) async {
      setUpMockChannel(tester.binding);

      await service.playRecordingStart();

      final args = log.first.arguments as Map;
      expect(args['volume'], 1.0);
    });

    testWidgets('handles platform error gracefully', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          throw PlatformException(code: 'ERROR', message: 'boom');
        },
      );

      // Should not throw.
      await service.playRecordingStart(volume: 0.5);
    });

    testWidgets('handles sound not found gracefully', (tester) async {
      setUpMockChannel(
        tester.binding,
        result: {'success': false, 'error': 'Sound not found'},
      );

      // Should not throw.
      await service.playRecordingStart(volume: 0.5);
    });

    test('can be instantiated', () {
      final s = SoundServiceImpl();
      expect(s, isA<SoundService>());
      s.dispose();
    });
  });
}
