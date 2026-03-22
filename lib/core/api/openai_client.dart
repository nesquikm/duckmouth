import 'dart:convert';

import 'package:http/http.dart' as http;

/// Default configuration constants for the OpenAI-compatible API.
const kDefaultBaseUrl = 'https://api.openai.com';
const kDefaultModel = 'whisper-1';

/// Abstract interface for an OpenAI-compatible API client.
abstract class OpenAiClient {
  /// Transcribe an audio file and return the transcription text.
  Future<String> transcribe(String audioFilePath);
}

/// HTTP-based implementation of [OpenAiClient].
class OpenAiClientImpl implements OpenAiClient {
  OpenAiClientImpl({
    required String apiKey,
    String baseUrl = kDefaultBaseUrl,
    String model = kDefaultModel,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _model = model,
        _httpClient = httpClient ?? http.Client();

  final String _apiKey;
  final String _baseUrl;
  final String _model;
  final http.Client _httpClient;

  @override
  Future<String> transcribe(String audioFilePath) async {
    final uri = Uri.parse('$_baseUrl/v1/audio/transcriptions');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = _model
      ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw OpenAiClientException(
        'Transcription failed with status ${response.statusCode}: '
        '${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = json['text'] as String?;
    if (text == null) {
      throw const OpenAiClientException(
        'Invalid response: missing "text" field',
      );
    }

    return text;
  }
}

/// Exception thrown by [OpenAiClient] operations.
class OpenAiClientException implements Exception {
  const OpenAiClientException(this.message);

  final String message;

  @override
  String toString() => 'OpenAiClientException: $message';
}
