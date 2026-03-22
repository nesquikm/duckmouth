import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/api/llm_client.dart';
import 'package:duckmouth/features/post_processing/data/post_processing_repository_impl.dart';

class MockLlmClient extends Mock implements LlmClient {}

void main() {
  late MockLlmClient mockClient;
  late PostProcessingRepositoryImpl repository;

  setUp(() {
    mockClient = MockLlmClient();
    repository = PostProcessingRepositoryImpl(client: mockClient);
  });

  group('PostProcessingRepositoryImpl', () {
    test('delegates to LlmClient.chatCompletion', () async {
      when(() => mockClient.chatCompletion(any(), any()))
          .thenAnswer((_) async => 'processed result');

      final result = await repository.process('raw text', 'Fix grammar');

      expect(result, 'processed result');
      verify(() => mockClient.chatCompletion('Fix grammar', 'raw text'))
          .called(1);
    });

    test('propagates exceptions from LlmClient', () async {
      when(() => mockClient.chatCompletion(any(), any()))
          .thenThrow(const LlmClientException('API error'));

      expect(
        () => repository.process('text', 'prompt'),
        throwsA(isA<LlmClientException>()),
      );
    });
  });
}
