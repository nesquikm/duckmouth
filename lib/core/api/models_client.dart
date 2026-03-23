import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Result of a model fetch operation.
sealed class FetchModelsResult {
  const FetchModelsResult();
}

/// Successful model fetch with a list of model IDs.
final class FetchModelsSuccess extends FetchModelsResult {
  const FetchModelsSuccess(this.models);
  final List<String> models;
}

/// Failed model fetch with a human-readable reason.
final class FetchModelsFailure extends FetchModelsResult {
  const FetchModelsFailure(this.reason);
  final String reason;
}

/// Client for fetching available models from an OpenAI-compatible `/models` endpoint.
abstract class ModelsClient {
  /// Fetch the list of model IDs from the configured provider.
  Future<FetchModelsResult> fetchModels({
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
  Future<FetchModelsResult> fetchModels({
    required String baseUrl,
    required String apiKey,
  }) async {
    if (baseUrl.isEmpty || apiKey.isEmpty) {
      return const FetchModelsFailure('Base URL and API key are required');
    }

    try {
      final uri = Uri.parse('$baseUrl/models');
      _log.fine('Fetching models from $uri');

      final response = await _httpClient.get(
        uri,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode != 200) {
        _log.warning('Models API error ${response.statusCode}');
        return FetchModelsFailure(_errorReason(response.statusCode));
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>?;
      if (data == null) {
        return const FetchModelsFailure('Unexpected response format');
      }

      final models = data
          .map((item) => (item as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toList()
        ..sort();

      _log.fine('Fetched ${models.length} models');
      return FetchModelsSuccess(models);
    } on SocketException {
      _log.warning('Network error fetching models');
      return const FetchModelsFailure(
        'Network error \u2014 check connection',
      );
    } on FormatException {
      _log.warning('Malformed JSON from models endpoint');
      return const FetchModelsFailure('Unexpected response format');
    } on Exception catch (e) {
      _log.warning('Failed to fetch models', e);
      return const FetchModelsFailure(
        'Network error \u2014 check connection',
      );
    }
  }

  static String _errorReason(int statusCode) {
    return switch (statusCode) {
      401 => 'Unauthorized \u2014 check API key',
      403 => 'Access denied \u2014 check API key permissions',
      404 => 'Not found \u2014 check endpoint URL',
      429 => 'Rate limited \u2014 try again later',
      >= 500 => 'Server error ($statusCode)',
      _ => 'HTTP error $statusCode',
    };
  }
}
