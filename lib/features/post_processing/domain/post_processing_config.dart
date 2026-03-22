import 'package:duckmouth/features/settings/domain/api_config.dart';

/// Default post-processing prompt.
const kDefaultPostProcessingPrompt =
    'Fix any grammar or spelling errors in the following transcription. '
    'Keep the original meaning and tone.';

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
