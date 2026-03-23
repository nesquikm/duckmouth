import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:duckmouth/core/api/openai_client.dart';

void main() {
  late Directory tempDir;
  late String testAudioPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('openai_client_test_');
    testAudioPath = '${tempDir.path}/test_audio.m4a';
    File(testAudioPath).writeAsBytesSync([0, 1, 2, 3]);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('OpenAiClientImpl', () {
    test('sends correct request to transcription endpoint', () async {
      http.Request? capturedRequest;

      final mockClient = http_testing.MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'text': 'hello world'}), 200);
      });

      final client = OpenAiClientImpl(
        apiKey: 'test-key',
        baseUrl: 'https://api.example.com/v1',
        model: 'whisper-1',
        httpClient: mockClient,
      );

      await client.transcribe(testAudioPath);

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'POST');
      expect(
        capturedRequest!.url.toString(),
        'https://api.example.com/v1/audio/transcriptions',
      );
      expect(
        capturedRequest!.headers['Authorization'],
        'Bearer test-key',
      );
      // Verify it's a multipart request by checking content-type
      expect(
        capturedRequest!.headers['content-type'],
        contains('multipart/form-data'),
      );
      // Verify the body contains the model field and file field
      final body = capturedRequest!.body;
      expect(body, contains('whisper-1'));
      expect(body, contains('file'));
    });

    test('returns transcription text on success', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response(
          jsonEncode({'text': 'The quick brown fox'}),
          200,
        );
      });

      final client = OpenAiClientImpl(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      final result = await client.transcribe(testAudioPath);
      expect(result, 'The quick brown fox');
    });

    test('throws OpenAiClientException on non-200 status', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response('Unauthorized', 401);
      });

      final client = OpenAiClientImpl(
        apiKey: 'bad-key',
        httpClient: mockClient,
      );

      expect(
        () => client.transcribe(testAudioPath),
        throwsA(isA<OpenAiClientException>()),
      );
    });

    test('provides user-friendly message for 401 status', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response('Unauthorized', 401);
      });

      final client = OpenAiClientImpl(
        apiKey: 'bad-key',
        httpClient: mockClient,
      );

      try {
        await client.transcribe(testAudioPath);
        fail('Should have thrown');
      } on OpenAiClientException catch (e) {
        expect(e.statusCode, 401);
        expect(e.message, contains('Invalid API key'));
      }
    });

    test('provides user-friendly message for 429 status', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response('Rate limited', 429);
      });

      final client = OpenAiClientImpl(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      try {
        await client.transcribe(testAudioPath);
        fail('Should have thrown');
      } on OpenAiClientException catch (e) {
        expect(e.statusCode, 429);
        expect(e.message, contains('Rate limit'));
      }
    });

    test('provides user-friendly message for 500 status', () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response('Internal Server Error', 500);
      });

      final client = OpenAiClientImpl(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      try {
        await client.transcribe(testAudioPath);
        fail('Should have thrown');
      } on OpenAiClientException catch (e) {
        expect(e.statusCode, 500);
        expect(e.message, contains('Server error'));
      }
    });

    test('throws OpenAiClientException when response missing text field',
        () async {
      final mockClient = http_testing.MockClient((_) async {
        return http.Response(jsonEncode({'result': 'oops'}), 200);
      });

      final client = OpenAiClientImpl(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      expect(
        () => client.transcribe(testAudioPath),
        throwsA(isA<OpenAiClientException>()),
      );
    });

    test('throws when network request fails', () async {
      final mockClient = http_testing.MockClient((_) async {
        throw const SocketException('No internet');
      });

      final client = OpenAiClientImpl(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      expect(
        () => client.transcribe(testAudioPath),
        throwsA(isA<SocketException>()),
      );
    });

    test('uses default base URL and model when not specified', () async {
      http.Request? capturedRequest;

      final mockClient = http_testing.MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'text': 'hi'}), 200);
      });

      final client = OpenAiClientImpl(
        apiKey: 'test-key',
        httpClient: mockClient,
      );

      await client.transcribe(testAudioPath);

      expect(
        capturedRequest!.url.toString(),
        'https://api.openai.com/v1/audio/transcriptions',
      );
      final body = capturedRequest!.body;
      expect(body, contains('whisper-1'));
    });
  });
}
