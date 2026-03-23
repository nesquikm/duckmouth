import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/api/llm_client.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_state.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';

class MockPostProcessingRepository extends Mock
    implements PostProcessingRepository {}

void main() {
  late MockPostProcessingRepository mockRepo;

  const enabledConfig = PostProcessingConfig(
    enabled: true,
    prompt: 'Fix grammar',
    llmConfig: ApiConfig(
      baseUrl: 'https://api.openai.com',
      apiKey: 'key',
      model: 'gpt-4.1-mini',
      providerName: 'openAi',
    ),
  );

  const disabledConfig = PostProcessingConfig(
    enabled: false,
    prompt: 'Fix grammar',
  );

  setUp(() {
    mockRepo = MockPostProcessingRepository();
  });

  group('PostProcessingCubit', () {
    test('initial state is PostProcessingIdle', () {
      final cubit = PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: disabledConfig,
      );
      expect(cubit.state, const PostProcessingIdle());
      cubit.close();
    });

    blocTest<PostProcessingCubit, PostProcessingState>(
      'emits [Idle, Disabled] when disabled (Idle resets for BlocListener)',
      build: () => PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: disabledConfig,
      ),
      act: (cubit) => cubit.process('hello'),
      expect: () => [
        const PostProcessingIdle(),
        const PostProcessingDisabled(),
      ],
      verify: (_) {
        verifyNever(() => mockRepo.process(any(), any()));
      },
    );

    blocTest<PostProcessingCubit, PostProcessingState>(
      'emits [Idle, Loading, Success] when enabled and processing succeeds',
      setUp: () {
        when(() => mockRepo.process(any(), any()))
            .thenAnswer((_) async => 'Fixed text');
      },
      build: () => PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: enabledConfig,
      ),
      act: (cubit) => cubit.process('raw text'),
      expect: () => [
        const PostProcessingIdle(),
        const PostProcessingLoading(rawText: 'raw text'),
        const PostProcessingSuccess(
          rawText: 'raw text',
          processedText: 'Fixed text',
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.process('raw text', 'Fix grammar')).called(1);
      },
    );

    blocTest<PostProcessingCubit, PostProcessingState>(
      'emits [Idle, Loading, Error] with friendly message on generic exception',
      setUp: () {
        when(() => mockRepo.process(any(), any()))
            .thenThrow(Exception('API error'));
      },
      build: () => PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: enabledConfig,
      ),
      act: (cubit) => cubit.process('raw text'),
      expect: () => [
        const PostProcessingIdle(),
        const PostProcessingLoading(rawText: 'raw text'),
        const PostProcessingError(
          rawText: 'raw text',
          message: 'Post-processing failed. Please try again.',
        ),
      ],
    );

    blocTest<PostProcessingCubit, PostProcessingState>(
      'emits [Idle, Loading, Error] with API message on LlmClientException',
      setUp: () {
        when(() => mockRepo.process(any(), any())).thenThrow(
          const LlmClientException(
            'Invalid LLM API key. Check your post-processing API key '
            'in Settings.',
            statusCode: 401,
          ),
        );
      },
      build: () => PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: enabledConfig,
      ),
      act: (cubit) => cubit.process('raw text'),
      expect: () => [
        const PostProcessingIdle(),
        const PostProcessingLoading(rawText: 'raw text'),
        const PostProcessingError(
          rawText: 'raw text',
          message: 'Invalid LLM API key. Check your post-processing API key '
              'in Settings.',
        ),
      ],
    );

    blocTest<PostProcessingCubit, PostProcessingState>(
      'emits [Idle, Loading, Error] with network message on SocketException',
      setUp: () {
        when(() => mockRepo.process(any(), any()))
            .thenThrow(const SocketException('No internet'));
      },
      build: () => PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: enabledConfig,
      ),
      act: (cubit) => cubit.process('raw text'),
      expect: () => [
        const PostProcessingIdle(),
        const PostProcessingLoading(rawText: 'raw text'),
        const PostProcessingError(
          rawText: 'raw text',
          message: 'Network error. Check your internet connection.',
        ),
      ],
    );

    blocTest<PostProcessingCubit, PostProcessingState>(
      'updateConfig changes behavior from disabled to enabled',
      setUp: () {
        when(() => mockRepo.process(any(), any()))
            .thenAnswer((_) async => 'processed');
      },
      build: () => PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: disabledConfig,
      ),
      act: (cubit) async {
        await cubit.process('text');
        cubit.updateConfig(enabledConfig);
        await cubit.process('text');
      },
      expect: () => [
        const PostProcessingIdle(),
        const PostProcessingDisabled(),
        const PostProcessingIdle(),
        const PostProcessingLoading(rawText: 'text'),
        const PostProcessingSuccess(
          rawText: 'text',
          processedText: 'processed',
        ),
      ],
    );

    blocTest<PostProcessingCubit, PostProcessingState>(
      'reset emits PostProcessingIdle',
      build: () => PostProcessingCubit(
        repositoryFactory: () => mockRepo,
        config: enabledConfig,
      ),
      seed: () => const PostProcessingSuccess(
        rawText: 'raw',
        processedText: 'processed',
      ),
      act: (cubit) => cubit.reset(),
      expect: () => [const PostProcessingIdle()],
    );
  });
}
