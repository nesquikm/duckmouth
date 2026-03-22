import 'package:duckmouth/features/transcription/domain/stt_repository.dart';

/// Fake STT repository that returns canned transcription text.
/// Can be configured to throw on the first N calls for error scenarios.
class FakeSttRepository implements SttRepository {
  FakeSttRepository({
    this.transcriptionText = 'Hello world, this is a test transcription.',
    this.failCount = 0,
    this.errorMessage = 'Fake STT error',
  });

  final String transcriptionText;

  /// Number of times to fail before succeeding.
  int failCount;
  final String errorMessage;
  int _callCount = 0;

  @override
  Future<String> transcribe(String audioFilePath) async {
    _callCount++;
    if (_callCount <= failCount) {
      throw Exception(errorMessage);
    }
    return transcriptionText;
  }
}
