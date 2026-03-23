import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Default configuration constants for the OpenAI-compatible API.
const kDefaultBaseUrl = 'https://api.openai.com/v1';
const kDefaultModel = 'whisper-1';

/// Abstract interface for an OpenAI-compatible API client.
abstract class OpenAiClient {
  /// Transcribe an audio file and return the transcription text.
  Future<String> transcribe(String audioFilePath);
}

/// HTTP-based implementation of [OpenAiClient].
class OpenAiClientImpl implements OpenAiClient {
  static final _log = Logger('OpenAiClient');

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
    _log.info('Transcribing $audioFilePath (model: $_model)');
    final uri = Uri.parse('$_baseUrl/audio/transcriptions');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = _model
      ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      _log.warning('STT API error ${response.statusCode}: ${response.body}');
      throw OpenAiClientException(
        _userFriendlyMessage(response.statusCode, response.body),
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = json['text'] as String?;
    if (text == null) {
      _log.warning('STT API returned no text field');
      throw const OpenAiClientException(
        'Invalid response: missing "text" field',
      );
    }

    _log.fine('Transcription complete (${text.length} chars)');
    return text;
  }
}

/// Returns a user-friendly error message based on the HTTP status code.
String _userFriendlyMessage(int statusCode, String body) {
  switch (statusCode) {
    case 401:
      return 'Invalid API key. Check your API key in Settings.';
    case 403:
      return 'Access denied. Your API key may lack permissions.';
    case 429:
      return 'Rate limit exceeded. Please wait a moment and try again.';
    case >= 500:
      return 'Server error ($statusCode). The API service may be '
          'temporarily unavailable.';
    default:
      return 'Transcription failed (HTTP $statusCode).';
  }
}

/// Exception thrown by [OpenAiClient] operations.
class OpenAiClientException implements Exception {
  const OpenAiClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'OpenAiClientException: $message';
}
