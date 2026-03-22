import 'package:duckmouth/features/settings/domain/api_config.dart';

/// Default post-processing prompt.
const kDefaultPostProcessingPrompt =
    'Fix any grammar or spelling errors in the following transcription. '
    'Keep the original meaning and tone.';

/// Predefined prompt templates for common post-processing tasks.
enum PromptTemplate {
  fixGrammar(
    'Fix Grammar',
    'Fix any grammar or spelling errors in the following transcription. '
        'Keep the original meaning and tone.',
  ),
  summarize(
    'Summarize',
    'Summarize the following transcription into a concise paragraph. '
        'Capture the key points.',
  ),
  translate(
    'Translate',
    'Translate the following transcription into English. '
        'Preserve the original meaning and tone.',
  ),
  reformat(
    'Reformat',
    'Reformat the following transcription into clean, well-structured text. '
        'Add punctuation, paragraphs, and fix any run-on sentences.',
  ),
  custom('Custom', '');

  const PromptTemplate(this.label, this.prompt);

  final String label;
  final String prompt;
}

/// Configuration for the LLM post-processing feature.
class PostProcessingConfig {
  const PostProcessingConfig({
    this.enabled = false,
    this.prompt = kDefaultPostProcessingPrompt,
    this.llmConfig = const ApiConfig(
      baseUrl: 'https://api.openai.com',
      apiKey: '',
      model: 'gpt-4o-mini',
      providerName: 'openAi',
    ),
  });

  final bool enabled;
  final String prompt;
  final ApiConfig llmConfig;

  PostProcessingConfig copyWith({
    bool? enabled,
    String? prompt,
    ApiConfig? llmConfig,
  }) {
    return PostProcessingConfig(
      enabled: enabled ?? this.enabled,
      prompt: prompt ?? this.prompt,
      llmConfig: llmConfig ?? this.llmConfig,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostProcessingConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          prompt == other.prompt &&
          llmConfig == other.llmConfig;

  @override
  int get hashCode => Object.hash(enabled, prompt, llmConfig);

  @override
  String toString() =>
      'PostProcessingConfig(enabled: $enabled, prompt: $prompt, '
      'llmConfig: $llmConfig)';
}
