import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:duckmouth/core/api/models_client.dart';

void main() {
  group('ModelsClientImpl', () {
    late ModelsClientImpl client;

    http_testing.MockClient mockHttp(
      Future<http.Response> Function(http.Request) handler,
    ) {
      return http_testing.MockClient(handler);
    }

    test('fetches and parses model list correctly', () async {
      final httpClient = mockHttp((request) async {
        expect(request.url.toString(), 'https://api.openai.com/v1/models');
        expect(request.headers['Authorization'], 'Bearer test-key');
        return http.Response(
          jsonEncode({
            'object': 'list',
            'data': [
              {'id': 'gpt-4o', 'object': 'model'},
              {'id': 'whisper-1', 'object': 'model'},
              {'id': 'gpt-3.5-turbo', 'object': 'model'},
            ],
          }),
          200,
        );
      });

      client = ModelsClientImpl(httpClient: httpClient);
      final models = await client.fetchModels(
        baseUrl: 'https://api.openai.com',
        apiKey: 'test-key',
      );

      expect(models, ['gpt-3.5-turbo', 'gpt-4o', 'whisper-1']);
    });

    test('returns empty list on HTTP error', () async {
      final httpClient = mockHttp((_) async => http.Response('Unauthorized', 401));
      client = ModelsClientImpl(httpClient: httpClient);

      final models = await client.fetchModels(
        baseUrl: 'https://api.openai.com',
        apiKey: 'bad-key',
      );

      expect(models, isEmpty);
    });

    test('returns empty list on network error', () async {
      final httpClient = mockHttp((_) => throw Exception('network down'));
      client = ModelsClientImpl(httpClient: httpClient);

      final models = await client.fetchModels(
        baseUrl: 'https://api.openai.com',
        apiKey: 'test-key',
      );

      expect(models, isEmpty);
    });

    test('handles malformed JSON gracefully', () async {
      final httpClient = mockHttp((_) async => http.Response('not json', 200));
      client = ModelsClientImpl(httpClient: httpClient);

      final models = await client.fetchModels(
        baseUrl: 'https://api.openai.com',
        apiKey: 'test-key',
      );

      expect(models, isEmpty);
    });

    test('handles missing data field', () async {
      final httpClient = mockHttp(
        (_) async => http.Response(jsonEncode({'object': 'list'}), 200),
      );
      client = ModelsClientImpl(httpClient: httpClient);

      final models = await client.fetchModels(
        baseUrl: 'https://api.openai.com',
        apiKey: 'test-key',
      );

      expect(models, isEmpty);
    });

    test('returns empty list when baseUrl is empty', () async {
      client = ModelsClientImpl();
      final models = await client.fetchModels(baseUrl: '', apiKey: 'key');
      expect(models, isEmpty);
    });

    test('returns empty list when apiKey is empty', () async {
      client = ModelsClientImpl();
      final models = await client.fetchModels(
        baseUrl: 'https://api.openai.com',
        apiKey: '',
      );
      expect(models, isEmpty);
    });
  });
}
