/// Configuration for an OpenAI-compatible API endpoint.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.providerName,
  });

  final String baseUrl;
  final String apiKey;
  final String model;
  final String providerName;

  ApiConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    String? providerName,
  }) {
    return ApiConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      providerName: providerName ?? this.providerName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiConfig &&
          runtimeType == other.runtimeType &&
          baseUrl == other.baseUrl &&
          apiKey == other.apiKey &&
          model == other.model &&
          providerName == other.providerName;

  @override
  int get hashCode => Object.hash(baseUrl, apiKey, model, providerName);

  @override
  String toString() =>
      'ApiConfig(baseUrl: $baseUrl, model: $model, provider: $providerName)';
}
