import 'dart:convert';
import 'dart:io';

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
      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsSuccess>());
      expect(
        (result as FetchModelsSuccess).models,
        ['gpt-3.5-turbo', 'gpt-4o', 'whisper-1'],
      );
    });

    test('returns failure with reason on 401', () async {
      final httpClient =
          mockHttp((_) async => http.Response('Unauthorized', 401));
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'bad-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect(
        (result as FetchModelsFailure).reason,
        contains('Unauthorized'),
      );
    });

    test('returns failure with reason on 403', () async {
      final httpClient =
          mockHttp((_) async => http.Response('Forbidden', 403));
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect((result as FetchModelsFailure).reason, contains('Access denied'));
    });

    test('returns failure with reason on 404', () async {
      final httpClient =
          mockHttp((_) async => http.Response('Not Found', 404));
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect((result as FetchModelsFailure).reason, contains('Not found'));
    });

    test('returns failure with reason on 429', () async {
      final httpClient =
          mockHttp((_) async => http.Response('Too Many Requests', 429));
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect((result as FetchModelsFailure).reason, contains('Rate limited'));
    });

    test('returns failure with reason on 5xx', () async {
      final httpClient = mockHttp(
        (_) async => http.Response('Internal Server Error', 500),
      );
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect((result as FetchModelsFailure).reason, contains('Server error'));
    });

    test('returns failure on network error', () async {
      final httpClient =
          mockHttp((_) => throw const SocketException('network down'));
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect((result as FetchModelsFailure).reason, contains('Network error'));
    });

    test('returns failure on malformed JSON', () async {
      final httpClient = mockHttp((_) async => http.Response('not json', 200));
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect(
        (result as FetchModelsFailure).reason,
        contains('Unexpected response format'),
      );
    });

    test('returns failure on missing data field', () async {
      final httpClient = mockHttp(
        (_) async => http.Response(jsonEncode({'object': 'list'}), 200),
      );
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsFailure>());
      expect(
        (result as FetchModelsFailure).reason,
        contains('Unexpected response format'),
      );
    });

    test('returns failure when baseUrl is empty', () async {
      client = ModelsClientImpl();
      final result = await client.fetchModels(baseUrl: '', apiKey: 'key');
      expect(result, isA<FetchModelsFailure>());
    });

    test('returns failure when apiKey is empty', () async {
      client = ModelsClientImpl();
      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: '',
      );
      expect(result, isA<FetchModelsFailure>());
    });

    test('returns success with empty list when data array is empty', () async {
      final httpClient = mockHttp(
        (_) async => http.Response(jsonEncode({'data': []}), 200),
      );
      client = ModelsClientImpl(httpClient: httpClient);

      final result = await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );

      expect(result, isA<FetchModelsSuccess>());
      expect((result as FetchModelsSuccess).models, isEmpty);
    });

    test('constructs URL without adding /v1/ prefix', () async {
      final httpClient = mockHttp((request) async {
        expect(
          request.url.toString(),
          'https://api.openai.com/v1/models',
        );
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 'model-1'},
            ],
          }),
          200,
        );
      });

      client = ModelsClientImpl(httpClient: httpClient);
      await client.fetchModels(
        baseUrl: 'https://api.openai.com/v1',
        apiKey: 'test-key',
      );
    });
  });
}
