import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';

/// Implementation of [SttRepository] that delegates to an [OpenAiClient].
class SttRepositoryImpl implements SttRepository {
  const SttRepositoryImpl({required OpenAiClient client}) : _client = client;

  final OpenAiClient _client;

  @override
  Future<String> transcribe(String audioFilePath) {
    return _client.transcribe(audioFilePath);
  }
}
