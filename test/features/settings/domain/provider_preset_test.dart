import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/settings/domain/provider_preset.dart';

void main() {
  group('ProviderPreset', () {
    test('OpenAI preset has correct values', () {
      const preset = ProviderPreset.openAi;
      expect(preset.label, 'OpenAI');
      expect(preset.baseUrl, 'https://api.openai.com');
      expect(preset.model, 'whisper-1');
    });

    test('Groq preset has correct values', () {
      const preset = ProviderPreset.groq;
      expect(preset.label, 'Groq');
      expect(preset.baseUrl, 'https://api.groq.com/openai');
      expect(preset.model, 'whisper-large-v3-turbo');
    });

    test('Custom preset has empty defaults', () {
      const preset = ProviderPreset.custom;
      expect(preset.label, 'Custom');
      expect(preset.baseUrl, '');
      expect(preset.model, '');
    });

    test('toApiConfig creates correct config', () {
      final config =
          ProviderPreset.openAi.toApiConfig(apiKey: 'test-key');
      expect(config.baseUrl, 'https://api.openai.com');
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

    test('fromName returns correct preset', () {
      expect(ProviderPreset.fromName('openAi'), ProviderPreset.openAi);
      expect(ProviderPreset.fromName('groq'), ProviderPreset.groq);
      expect(ProviderPreset.fromName('custom'), ProviderPreset.custom);
    });

    test('fromName returns custom for unknown name', () {
      expect(ProviderPreset.fromName('unknown'), ProviderPreset.custom);
    });
  });
}
