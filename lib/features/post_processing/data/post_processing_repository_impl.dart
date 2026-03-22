import 'package:duckmouth/core/api/llm_client.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';

/// Implementation of [PostProcessingRepository] using an [LlmClient].
class PostProcessingRepositoryImpl implements PostProcessingRepository {
  const PostProcessingRepositoryImpl({required LlmClient client})
      : _client = client;

  final LlmClient _client;

  @override
  Future<String> process(String text, String prompt) {
    return _client.chatCompletion(prompt, text);
  }
}
