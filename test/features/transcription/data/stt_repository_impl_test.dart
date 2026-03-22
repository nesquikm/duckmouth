import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/features/transcription/data/stt_repository_impl.dart';

class MockOpenAiClient extends Mock implements OpenAiClient {}

void main() {
  late MockOpenAiClient mockClient;
  late SttRepositoryImpl repository;

  setUp(() {
    mockClient = MockOpenAiClient();
    repository = SttRepositoryImpl(client: mockClient);
  });

  group('SttRepositoryImpl', () {
    test('delegates transcribe call to OpenAiClient', () async {
      when(() => mockClient.transcribe('/audio.m4a'))
          .thenAnswer((_) async => 'transcribed text');

      final result = await repository.transcribe('/audio.m4a');

      expect(result, 'transcribed text');
      verify(() => mockClient.transcribe('/audio.m4a')).called(1);
    });

    test('propagates exceptions from client', () async {
      when(() => mockClient.transcribe(any()))
          .thenThrow(const OpenAiClientException('fail'));

      expect(
        () => repository.transcribe('/audio.m4a'),
        throwsA(isA<OpenAiClientException>()),
      );
    });
  });
}
