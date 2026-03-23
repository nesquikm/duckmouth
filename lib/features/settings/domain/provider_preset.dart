import 'package:duckmouth/features/settings/domain/api_config.dart';

/// Preset configurations for known API providers.
enum ProviderPreset {
  openAi(
    label: 'OpenAI',
    baseUrl: 'https://api.openai.com',
    model: 'whisper-1',
    llmModel: 'gpt-4.1-mini',
  ),
  groq(
    label: 'Groq',
    baseUrl: 'https://api.groq.com/openai',
    model: 'whisper-large-v3-turbo',
    llmModel: 'llama-3.3-70b-versatile',
  ),
  custom(
    label: 'Custom',
    baseUrl: '',
    model: '',
    llmModel: '',
  );

  const ProviderPreset({
    required this.label,
    required this.baseUrl,
    required this.model,
    required this.llmModel,
  });

  final String label;
  final String baseUrl;
  final String model;
  final String llmModel;

  /// Create an [ApiConfig] from this preset, using the given [apiKey].
  ///
  /// For [custom], the caller should supply [baseUrl] and [model] overrides.
  ApiConfig toApiConfig({
    required String apiKey,
    String? baseUrl,
    String? model,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey,
      model: model ?? this.model,
      providerName: name,
    );
  }

  /// Look up a preset by its [name]. Falls back to [custom] if not found.
  static ProviderPreset fromName(String name) {
    return ProviderPreset.values.firstWhere(
      (p) => p.name == name,
      orElse: () => ProviderPreset.custom,
    );
  }
}
