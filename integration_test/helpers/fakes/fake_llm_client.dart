import 'package:duckmouth/core/api/llm_client.dart';

/// No-op LLM client for integration tests.
/// This exists to prevent `updateLlmClient()` from crashing
/// when it resolves the client to create PostProcessingRepositoryImpl.
class FakeLlmClient implements LlmClient {
  @override
  Future<String> chatCompletion(String systemPrompt, String userMessage) async {
    return 'fake processed text';
  }
}
