import 'dart:convert';

import 'package:http/http.dart' as http;

/// Abstract interface for an LLM chat completions client.
abstract class LlmClient {
  /// Send a chat completion request and return the assistant's reply.
  Future<String> chatCompletion(String systemPrompt, String userMessage);
}

/// HTTP-based implementation of [LlmClient] targeting OpenAI-compatible APIs.
class LlmClientImpl implements LlmClient {
  LlmClientImpl({
    required String apiKey,
    required String baseUrl,
    required String model,
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
  Future<String> chatCompletion(String systemPrompt, String userMessage) async {
    final uri = Uri.parse('$_baseUrl/v1/chat/completions');

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
    });

    final response = await _httpClient.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw LlmClientException(
        _llmUserFriendlyMessage(response.statusCode, response.body),
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const LlmClientException(
        'Invalid response: missing or empty "choices" field',
      );
    }

    final message =
        (choices[0] as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null) {
      throw const LlmClientException(
        'Invalid response: missing "content" in message',
      );
    }

    return content;
  }
}

/// Returns a user-friendly error message based on the HTTP status code.
String _llmUserFriendlyMessage(int statusCode, String body) {
  switch (statusCode) {
    case 401:
      return 'Invalid LLM API key. Check your post-processing API key '
          'in Settings.';
    case 403:
      return 'Access denied. Your LLM API key may lack permissions.';
    case 429:
      return 'Rate limit exceeded. Please wait a moment and try again.';
    case >= 500:
      return 'LLM server error ($statusCode). The API service may be '
          'temporarily unavailable.';
    default:
      return 'Post-processing failed (HTTP $statusCode).';
  }
}

/// Exception thrown by [LlmClient] operations.
class LlmClientException implements Exception {
  const LlmClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'LlmClientException: $message';
}
