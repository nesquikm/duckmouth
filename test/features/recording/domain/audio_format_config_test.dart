import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

import 'package:duckmouth/features/recording/domain/audio_format_config.dart';

void main() {
  group('AudioFormat', () {
    test('has correct labels', () {
      expect(AudioFormat.wav.label, 'WAV');
      expect(AudioFormat.flac.label, 'FLAC');
      expect(AudioFormat.aac.label, 'AAC (m4a)');
      expect(AudioFormat.opus.label, 'Opus (ogg)');
    });

    test('has correct extensions', () {
      expect(AudioFormat.wav.extension, 'wav');
      expect(AudioFormat.flac.extension, 'flac');
      expect(AudioFormat.aac.extension, 'm4a');
      expect(AudioFormat.opus.extension, 'ogg');
    });

    test('has correct encoders', () {
      expect(AudioFormat.wav.encoder, AudioEncoder.wav);
      expect(AudioFormat.flac.encoder, AudioEncoder.flac);
      expect(AudioFormat.aac.encoder, AudioEncoder.aacLc);
      expect(AudioFormat.opus.encoder, AudioEncoder.opus);
    });
  });

  group('QualityPreset', () {
    test('bestCompatibility has correct defaults', () {
      expect(QualityPreset.bestCompatibility.format, AudioFormat.wav);
      expect(QualityPreset.bestCompatibility.sampleRate, 16000);
      expect(QualityPreset.bestCompatibility.bitRate, isNull);
    });

    test('balanced has correct defaults', () {
      expect(QualityPreset.balanced.format, AudioFormat.aac);
      expect(QualityPreset.balanced.sampleRate, 16000);
      expect(QualityPreset.balanced.bitRate, 64000);
    });

    test('smallest has correct defaults', () {
      expect(QualityPreset.smallest.format, AudioFormat.aac);
      expect(QualityPreset.smallest.sampleRate, 16000);
      expect(QualityPreset.smallest.bitRate, 32000);
    });

    test('custom has correct defaults', () {
      expect(QualityPreset.custom.format, AudioFormat.wav);
      expect(QualityPreset.custom.sampleRate, 16000);
      expect(QualityPreset.custom.bitRate, isNull);
    });
  });

  group('AudioFormatConfig', () {
    test('defaults to WAV 16kHz bestCompatibility preset', () {
      const config = AudioFormatConfig();
      expect(config.preset, QualityPreset.bestCompatibility);
      expect(config.format, AudioFormat.wav);
      expect(config.sampleRate, 16000);
      expect(config.bitRate, isNull);
    });

    test('effectiveFormat uses preset values for non-custom', () {
      const config = AudioFormatConfig(
        preset: QualityPreset.balanced,
        format: AudioFormat.opus, // should be ignored
      );
      expect(config.effectiveFormat, AudioFormat.aac);
    });

    test('effectiveSampleRate uses preset values for non-custom', () {
      const config = AudioFormatConfig(
        preset: QualityPreset.balanced,
        sampleRate: 48000, // should be ignored
      );
      expect(config.effectiveSampleRate, 16000);
    });

    test('effectiveBitRate uses preset values for non-custom', () {
      const config = AudioFormatConfig(
        preset: QualityPreset.balanced,
        bitRate: 999, // should be ignored
      );
      expect(config.effectiveBitRate, 64000);
    });

    test('effectiveFormat uses manual values for custom', () {
      const config = AudioFormatConfig(
        preset: QualityPreset.custom,
        format: AudioFormat.opus,
      );
      expect(config.effectiveFormat, AudioFormat.opus);
    });

    test('effectiveSampleRate uses manual values for custom', () {
      const config = AudioFormatConfig(
        preset: QualityPreset.custom,
        sampleRate: 48000,
      );
      expect(config.effectiveSampleRate, 48000);
    });

    test('effectiveBitRate uses manual values for custom', () {
      const config = AudioFormatConfig(
        preset: QualityPreset.custom,
        bitRate: 96000,
      );
      expect(config.effectiveBitRate, 96000);
    });

    test('copyWith works', () {
      const config = AudioFormatConfig();
      final copied = config.copyWith(
        preset: QualityPreset.smallest,
        format: AudioFormat.flac,
        sampleRate: 44100,
        bitRate: 128000,
      );
      expect(copied.preset, QualityPreset.smallest);
      expect(copied.format, AudioFormat.flac);
      expect(copied.sampleRate, 44100);
      expect(copied.bitRate, 128000);
    });

    test('copyWith preserves unspecified fields', () {
      const config = AudioFormatConfig(
        preset: QualityPreset.balanced,
        format: AudioFormat.aac,
        sampleRate: 22050,
        bitRate: 64000,
      );
      final copied = config.copyWith(sampleRate: 16000);
      expect(copied.preset, QualityPreset.balanced);
      expect(copied.format, AudioFormat.aac);
      expect(copied.sampleRate, 16000);
      expect(copied.bitRate, 64000);
    });

    test('equality works for equal configs', () {
      const a = AudioFormatConfig();
      const b = AudioFormatConfig();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality works for different configs', () {
      const a = AudioFormatConfig();
      const b = AudioFormatConfig(preset: QualityPreset.balanced);
      expect(a, isNot(equals(b)));
    });
  });
}
