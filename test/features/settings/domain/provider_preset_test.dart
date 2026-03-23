import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/settings/domain/provider_preset.dart';

void main() {
  group('ProviderPreset', () {
    test('OpenAI preset has correct values', () {
      const preset = ProviderPreset.openAi;
      expect(preset.label, 'OpenAI');
      expect(preset.baseUrl, 'https://api.openai.com/v1');
      expect(preset.model, 'whisper-1');
      expect(preset.llmModel, 'gpt-5.4-mini');
    });

    test('Groq preset has correct values', () {
      const preset = ProviderPreset.groq;
      expect(preset.label, 'Groq');
      expect(preset.baseUrl, 'https://api.groq.com/openai/v1');
      expect(preset.model, 'whisper-large-v3-turbo');
      expect(preset.llmModel, 'llama-3.3-70b-versatile');
    });

    test('xAI preset has correct values', () {
      const preset = ProviderPreset.xAi;
      expect(preset.label, 'xAI (Grok)');
      expect(preset.baseUrl, 'https://api.x.ai/v1');
      expect(preset.model, '');
      expect(preset.llmModel, 'grok-4-1-fast-non-reasoning');
    });

    test('Google Gemini preset has correct values', () {
      const preset = ProviderPreset.googleGemini;
      expect(preset.label, 'Google Gemini');
      expect(
        preset.baseUrl,
        'https://generativelanguage.googleapis.com/v1beta/openai',
      );
      expect(preset.model, '');
      expect(preset.llmModel, 'gemini-3-flash');
    });

    test('OpenRouter preset has correct values', () {
      const preset = ProviderPreset.openRouter;
      expect(preset.label, 'OpenRouter');
      expect(preset.baseUrl, 'https://openrouter.ai/api/v1');
      expect(preset.model, '');
      expect(preset.llmModel, 'openrouter/auto');
    });

    test('Custom preset has empty defaults', () {
      const preset = ProviderPreset.custom;
      expect(preset.label, 'Custom');
      expect(preset.baseUrl, '');
      expect(preset.model, '');
      expect(preset.llmModel, '');
    });

    test('toApiConfig creates correct config', () {
      final config = ProviderPreset.openAi.toApiConfig(apiKey: 'test-key');
      expect(config.baseUrl, 'https://api.openai.com/v1');
      expect(config.apiKey, 'test-key');
      expect(config.model, 'whisper-1');
      expect(config.providerName, 'openAi');
    });

    test('toApiConfig allows overriding baseUrl and model', () {
      final config = ProviderPreset.custom.toApiConfig(
        apiKey: 'key',
        baseUrl: 'https://my-api.com',
        model: 'my-model',
      );
      expect(config.baseUrl, 'https://my-api.com');
      expect(config.model, 'my-model');
      expect(config.providerName, 'custom');
    });

    test('toApiConfig works for new presets', () {
      final xaiConfig = ProviderPreset.xAi.toApiConfig(apiKey: 'k');
      expect(xaiConfig.baseUrl, 'https://api.x.ai/v1');
      expect(xaiConfig.providerName, 'xAi');

      final geminiConfig =
          ProviderPreset.googleGemini.toApiConfig(apiKey: 'k');
      expect(
        geminiConfig.baseUrl,
        'https://generativelanguage.googleapis.com/v1beta/openai',
      );
      expect(geminiConfig.providerName, 'googleGemini');

      final orConfig = ProviderPreset.openRouter.toApiConfig(apiKey: 'k');
      expect(orConfig.baseUrl, 'https://openrouter.ai/api/v1');
      expect(orConfig.providerName, 'openRouter');
    });

    test('fromName returns correct preset for all presets', () {
      expect(ProviderPreset.fromName('openAi'), ProviderPreset.openAi);
      expect(ProviderPreset.fromName('groq'), ProviderPreset.groq);
      expect(ProviderPreset.fromName('xAi'), ProviderPreset.xAi);
      expect(
          ProviderPreset.fromName('googleGemini'), ProviderPreset.googleGemini);
      expect(
          ProviderPreset.fromName('openRouter'), ProviderPreset.openRouter);
      expect(ProviderPreset.fromName('custom'), ProviderPreset.custom);
    });

    test('fromName returns custom for unknown name', () {
      expect(ProviderPreset.fromName('unknown'), ProviderPreset.custom);
    });

    test('llmModel differs from model for non-custom presets', () {
      expect(
          ProviderPreset.openAi.llmModel, isNot(ProviderPreset.openAi.model));
      expect(ProviderPreset.groq.llmModel, isNot(ProviderPreset.groq.model));
    });

    test('Groq llmModel is llama not whisper', () {
      expect(ProviderPreset.groq.llmModel, 'llama-3.3-70b-versatile');
      expect(ProviderPreset.groq.llmModel, isNot(contains('whisper')));
    });

    test('preset base URLs include version path', () {
      expect(ProviderPreset.openAi.baseUrl, endsWith('/v1'));
      expect(ProviderPreset.groq.baseUrl, endsWith('/v1'));
      expect(ProviderPreset.xAi.baseUrl, endsWith('/v1'));
      expect(ProviderPreset.openRouter.baseUrl, endsWith('/v1'));
      // Gemini uses /v1beta/openai path
      expect(ProviderPreset.googleGemini.baseUrl, contains('/v1beta/'));
    });

    test('STT-less presets have empty model', () {
      expect(ProviderPreset.xAi.model, isEmpty);
      expect(ProviderPreset.googleGemini.model, isEmpty);
      expect(ProviderPreset.openRouter.model, isEmpty);
    });

    test('all 6 presets exist', () {
      expect(ProviderPreset.values, hasLength(6));
    });
  });
}
