/// Abstract interface for LLM post-processing of transcribed text.
abstract class PostProcessingRepository {
  /// Process [text] using the given [prompt] and return the result.
  Future<String> process(String text, String prompt);
}
