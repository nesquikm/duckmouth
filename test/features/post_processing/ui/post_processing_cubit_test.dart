import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
      model: 'gpt-4o-mini',
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
        repository: mockRepo,
        config: disabledConfig,
      );
      expect(cubit.state, const PostProcessingIdle());
      cubit.close();
    });

    blocTest<PostProcessingCubit, PostProcessingState>(
      'emits PostProcessingDisabled when disabled',
      build: () => PostProcessingCubit(
        repository: mockRepo,
        config: disabledConfig,
      ),
      act: (cubit) => cubit.process('hello'),
      expect: () => [const PostProcessingDisabled()],
      verify: (_) {
        verifyNever(() => mockRepo.process(any(), any()));
      },
    );

    blocTest<PostProcessingCubit, PostProcessingState>(
      'emits [Loading, Success] when enabled and processing succeeds',
      setUp: () {
        when(() => mockRepo.process(any(), any()))
            .thenAnswer((_) async => 'Fixed text');
      },
      build: () => PostProcessingCubit(
        repository: mockRepo,
        config: enabledConfig,
      ),
      act: (cubit) => cubit.process('raw text'),
      expect: () => [
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
      'emits [Loading, Error] when enabled and processing fails',
      setUp: () {
        when(() => mockRepo.process(any(), any()))
            .thenThrow(Exception('API error'));
      },
      build: () => PostProcessingCubit(
        repository: mockRepo,
        config: enabledConfig,
      ),
      act: (cubit) => cubit.process('raw text'),
      expect: () => [
        const PostProcessingLoading(rawText: 'raw text'),
        const PostProcessingError(
          rawText: 'raw text',
          message: 'Exception: API error',
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
        repository: mockRepo,
        config: disabledConfig,
      ),
      act: (cubit) async {
        await cubit.process('text');
        cubit.updateConfig(enabledConfig);
        await cubit.process('text');
      },
      expect: () => [
        const PostProcessingDisabled(),
        const PostProcessingLoading(rawText: 'text'),
        const PostProcessingSuccess(
          rawText: 'text',
          processedText: 'processed',
        ),
      ],
    );
  });
}
