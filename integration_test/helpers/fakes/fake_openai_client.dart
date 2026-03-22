import 'package:duckmouth/core/api/openai_client.dart';

/// No-op OpenAI client for integration tests.
/// This exists to prevent `updateOpenAiClient()` from crashing
/// when it resolves the client to create SttRepositoryImpl.
class FakeOpenAiClient implements OpenAiClient {
  @override
  Future<String> transcribe(String audioFilePath) async {
    return 'fake transcription';
  }
}
