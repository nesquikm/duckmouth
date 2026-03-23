import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:duckmouth/core/api/llm_client.dart';

void main() {
  group('LlmClientImpl', () {
    test('sends correct request to chat completions endpoint', () async {
      http.Request? capturedRequest;
      String? capturedBody;

      final mockClient = http_testing.MockClient((request) async {
        capturedRequest = request;
        capturedBody = request.body;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Fixed text'},
              },
            ],
          }),
          200,
        );
      });

      final client = LlmClientImpl(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      await client.chatCompletion('Fix grammar', 'hello wrold');

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'POST');
      expect(
        capturedRequest!.url.toString(),
        'https://api.example.com/v1/chat/completions',
      );
      expect(capturedRequest!.headers['Authorization'], 'Bearer test-key');
      expect(capturedRequest!.headers['Content-Type'], 'application/json');

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['model'], 'gpt-5.4-mini');
      expect(body['messages'], hasLength(2));
      expect(body['messages'][0]['role'], 'system');
      expect(body['messages'][0]['content'], 'Fix grammar');
      expect(body['messages'][1]['role'], 'user');
      expect(body['messages'][1]['content'], 'hello wrold');
    });

    test('returns content from response', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'hello world'},
              },
            ],
          }),
          200,
        );
      });

      final client = LlmClientImpl(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      final result = await client.chatCompletion('Fix grammar', 'hello wrold');
      expect(result, 'hello world');
    });

    test('throws LlmClientException on non-200 status', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response('Unauthorized', 401);
      });

      final client = LlmClientImpl(
        apiKey: 'bad-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      expect(
        () => client.chatCompletion('prompt', 'text'),
        throwsA(isA<LlmClientException>()),
      );
    });

    test('provides user-friendly message for 401 status', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response('Unauthorized', 401);
      });

      final client = LlmClientImpl(
        apiKey: 'bad-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      try {
        await client.chatCompletion('prompt', 'text');
        fail('Should have thrown');
      } on LlmClientException catch (e) {
        expect(e.statusCode, 401);
        expect(e.message, contains('Invalid LLM API key'));
      }
    });

    test('provides user-friendly message for server error', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response('Internal Server Error', 502);
      });

      final client = LlmClientImpl(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      try {
        await client.chatCompletion('prompt', 'text');
        fail('Should have thrown');
      } on LlmClientException catch (e) {
        expect(e.statusCode, 502);
        expect(e.message, contains('server error'));
      }
    });

    test('throws LlmClientException when choices is missing', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response(jsonEncode({'id': 'abc'}), 200);
      });

      final client = LlmClientImpl(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      expect(
        () => client.chatCompletion('prompt', 'text'),
        throwsA(isA<LlmClientException>()),
      );
    });

    test('throws LlmClientException when choices is empty', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response(jsonEncode({'choices': []}), 200);
      });

      final client = LlmClientImpl(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      expect(
        () => client.chatCompletion('prompt', 'text'),
        throwsA(isA<LlmClientException>()),
      );
    });

    test('throws when network request fails', () async {
      final mockClient = http_testing.MockClient((_) async {
        throw const SocketException('No internet');
      });

      final client = LlmClientImpl(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com',
        model: 'gpt-5.4-mini',
        httpClient: mockClient,
      );

      expect(
        () => client.chatCompletion('prompt', 'text'),
        throwsA(isA<SocketException>()),
      );
    });
  });
}
