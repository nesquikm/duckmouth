import 'package:record/record.dart';

/// Supported audio output formats for recording.
enum AudioFormat {
  wav('WAV', 'wav', AudioEncoder.wav),
  flac('FLAC', 'flac', AudioEncoder.flac),
  aac('AAC (m4a)', 'm4a', AudioEncoder.aacLc),
  opus('Opus (ogg)', 'ogg', AudioEncoder.opus);

  const AudioFormat(this.label, this.extension, this.encoder);
  final String label;
  final String extension;
  final AudioEncoder encoder;
}

/// Predefined quality presets for audio recording.
enum QualityPreset {
  bestCompatibility(
    'Best compatibility',
    'WAV 16kHz 16-bit mono — works everywhere including whisper.cpp',
    AudioFormat.wav,
    16000,
    null,
  ),
  balanced(
    'Balanced',
    'AAC 64kbps 16kHz mono — good size/quality tradeoff',
    AudioFormat.aac,
    16000,
    64000,
  ),
  smallest(
    'Smallest',
    'AAC 32kbps 16kHz mono — minimum size',
    AudioFormat.aac,
    16000,
    32000,
  ),
  custom(
    'Custom',
    'Choose format and sample rate manually',
    AudioFormat.wav,
    16000,
    null,
  );

  const QualityPreset(
    this.label,
    this.description,
    this.format,
    this.sampleRate,
    this.bitRate,
  );

  final String label;
  final String description;
  final AudioFormat format;
  final int sampleRate;
  final int? bitRate;
}

/// Configuration for audio recording format and quality.
class AudioFormatConfig {
  const AudioFormatConfig({
    this.preset = QualityPreset.bestCompatibility,
    this.format = AudioFormat.wav,
    this.sampleRate = 16000,
    this.bitRate,
  });

  final QualityPreset preset;
  final AudioFormat format;
  final int sampleRate;
  final int? bitRate;

  /// Resolve effective format — preset overrides manual settings unless custom.
  AudioFormat get effectiveFormat =>
      preset == QualityPreset.custom ? format : preset.format;

  /// Resolve effective sample rate — preset overrides unless custom.
  int get effectiveSampleRate =>
      preset == QualityPreset.custom ? sampleRate : preset.sampleRate;

  /// Resolve effective bit rate — preset overrides unless custom.
  int? get effectiveBitRate =>
      preset == QualityPreset.custom ? bitRate : preset.bitRate;

  AudioFormatConfig copyWith({
    QualityPreset? preset,
    AudioFormat? format,
    int? sampleRate,
    int? bitRate,
  }) {
    return AudioFormatConfig(
      preset: preset ?? this.preset,
      format: format ?? this.format,
      sampleRate: sampleRate ?? this.sampleRate,
      bitRate: bitRate ?? this.bitRate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioFormatConfig &&
          runtimeType == other.runtimeType &&
          preset == other.preset &&
          format == other.format &&
          sampleRate == other.sampleRate &&
          bitRate == other.bitRate;

  @override
  int get hashCode => Object.hash(preset, format, sampleRate, bitRate);
}
