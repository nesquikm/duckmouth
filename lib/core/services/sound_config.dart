/// Configuration for sound feedback.
class SoundConfig {
  const SoundConfig({
    this.enabled = true,
    this.startVolume = 1.0,
    this.stopVolume = 1.0,
    this.completeVolume = 1.0,
  });

  /// Whether sound feedback is enabled globally.
  final bool enabled;

  /// Volume for the recording-start sound (0.0–1.0).
  final double startVolume;

  /// Volume for the recording-stop sound (0.0–1.0).
  final double stopVolume;

  /// Volume for the transcription-complete sound (0.0–1.0).
  final double completeVolume;

  SoundConfig copyWith({
    bool? enabled,
    double? startVolume,
    double? stopVolume,
    double? completeVolume,
  }) {
    return SoundConfig(
      enabled: enabled ?? this.enabled,
      startVolume: startVolume ?? this.startVolume,
      stopVolume: stopVolume ?? this.stopVolume,
      completeVolume: completeVolume ?? this.completeVolume,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoundConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          startVolume == other.startVolume &&
          stopVolume == other.stopVolume &&
          completeVolume == other.completeVolume;

  @override
  int get hashCode =>
      Object.hash(enabled, startVolume, stopVolume, completeVolume);
}
