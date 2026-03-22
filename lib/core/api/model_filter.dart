/// Heuristic filters to classify models as STT vs LLM.
class ModelFilter {
  /// Patterns that indicate a model is NOT a chat/completion LLM.
  static final _excludeLlmPatterns = [
    RegExp(r'whisper', caseSensitive: false),
    RegExp(r'tts', caseSensitive: false),
    RegExp(r'dall-e', caseSensitive: false),
    RegExp(r'text-embedding', caseSensitive: false),
    RegExp(r'embedding', caseSensitive: false),
    RegExp(r'image', caseSensitive: false),
    RegExp(r'moderation', caseSensitive: false),
  ];

  /// Returns models likely to be STT models (contain "whisper").
  static List<String> filterStt(List<String> models) {
    return models
        .where((m) => m.toLowerCase().contains('whisper'))
        .toList();
  }

  /// Returns models likely to be LLM chat/completion models
  /// (excludes embedding, tts, image, whisper, moderation patterns).
  static List<String> filterLlm(List<String> models) {
    return models
        .where((m) => !_excludeLlmPatterns.any((p) => p.hasMatch(m)))
        .toList();
  }
}
