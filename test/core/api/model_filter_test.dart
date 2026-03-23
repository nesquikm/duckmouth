import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/core/api/model_filter.dart';

void main() {
  group('ModelFilter.filterStt', () {
    test('includes whisper models', () {
      final models = [
        'gpt-4o',
        'whisper-1',
        'whisper-large-v3-turbo',
        'llama-3',
      ];

      expect(ModelFilter.filterStt(models), ['whisper-1', 'whisper-large-v3-turbo']);
    });

    test('is case-insensitive', () {
      expect(ModelFilter.filterStt(['Whisper-1', 'WHISPER-LARGE']), hasLength(2));
    });

    test('returns empty list when no whisper models', () {
      expect(ModelFilter.filterStt(['gpt-4o', 'llama-3']), isEmpty);
    });
  });

  group('ModelFilter.filterLlm', () {
    test('includes chat/completion models', () {
      final models = ['gpt-4o', 'llama-3', 'claude-3'];
      expect(ModelFilter.filterLlm(models), ['gpt-4o', 'llama-3', 'claude-3']);
    });

    test('excludes whisper models', () {
      final models = ['gpt-4o', 'whisper-1'];
      expect(ModelFilter.filterLlm(models), ['gpt-4o']);
    });

    test('excludes embedding models', () {
      final models = ['gpt-4o', 'text-embedding-ada-002', 'embedding-v1'];
      expect(ModelFilter.filterLlm(models), ['gpt-4o']);
    });

    test('excludes tts models', () {
      final models = ['gpt-4o', 'tts-1', 'tts-1-hd'];
      expect(ModelFilter.filterLlm(models), ['gpt-4o']);
    });

    test('excludes dall-e models', () {
      final models = ['gpt-4o', 'dall-e-3'];
      expect(ModelFilter.filterLlm(models), ['gpt-4o']);
    });

    test('excludes moderation models', () {
      final models = ['gpt-4o', 'text-moderation-latest'];
      expect(ModelFilter.filterLlm(models), ['gpt-4o']);
    });

    test('is case-insensitive', () {
      final models = ['gpt-4o', 'TTS-1', 'DALL-E-3', 'Whisper-1'];
      expect(ModelFilter.filterLlm(models), ['gpt-4o']);
    });

    test('does not exclude grok models', () {
      final models = ['grok-4-1-fast-non-reasoning', 'grok-beta'];
      expect(ModelFilter.filterLlm(models), models);
    });

    test('does not exclude gemini models', () {
      final models = ['gemini-3-flash', 'gemini-2.5-pro'];
      expect(ModelFilter.filterLlm(models), models);
    });

    test('does not exclude openrouter models', () {
      final models = ['openrouter/auto', 'openrouter/anthropic/claude-3'];
      expect(ModelFilter.filterLlm(models), models);
    });
  });
}
