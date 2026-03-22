import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';

/// Fake post-processing repository that returns canned processed text.
/// Can be configured to throw on the first N calls for error scenarios.
class FakePostProcessingRepository implements PostProcessingRepository {
  FakePostProcessingRepository({
    this.processedText = 'Hello world, this is a processed transcription.',
    this.failCount = 0,
    this.errorMessage = 'Fake post-processing error',
  });

  final String processedText;

  /// Number of times to fail before succeeding.
  int failCount;
  final String errorMessage;
  int _callCount = 0;

  @override
  Future<String> process(String text, String prompt) async {
    _callCount++;
    if (_callCount <= failCount) {
      throw Exception(errorMessage);
    }
    return processedText;
  }
}
