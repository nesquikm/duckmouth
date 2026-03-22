import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Client for fetching available models from an OpenAI-compatible `/v1/models` endpoint.
abstract class ModelsClient {
  /// Fetch the list of model IDs from the configured provider.
  /// Returns an empty list on any error.
  Future<List<String>> fetchModels({
    required String baseUrl,
    required String apiKey,
  });
}

/// HTTP-based implementation of [ModelsClient].
class ModelsClientImpl implements ModelsClient {
  static final _log = Logger('ModelsClient');

  ModelsClientImpl({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  @override
  Future<List<String>> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    if (baseUrl.isEmpty || apiKey.isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/v1/models');
      _log.fine('Fetching models from $uri');

      final response = await _httpClient.get(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode != 200) {
        _log.warning('Models API error ${response.statusCode}');
        return [];
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null) return [];

      final models = data
          .map((item) => (item as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toList()
        ..sort();

      _log.fine('Fetched ${models.length} models');
      return models;
    } on Exception catch (e) {
      _log.warning('Failed to fetch models', e);
      return [];
    }
  }
}
