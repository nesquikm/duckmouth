import 'dart:io';

/// Abstract interface for playing sound feedback.
abstract class SoundService {
  /// Play the recording-start sound.
  Future<void> playRecordingStart({double volume = 1.0});

  /// Play the recording-stop sound.
  Future<void> playRecordingStop({double volume = 1.0});

  /// Play the transcription-complete sound.
  Future<void> playTranscriptionComplete({double volume = 1.0});

  /// Release resources.
  void dispose();
}

/// macOS implementation that plays built-in system sounds via `afplay`.
class SoundServiceImpl implements SoundService {
  /// Play a macOS system sound by name.
  ///
  /// Uses `afplay` with the `-v` flag for volume control.
  /// Volume is clamped to 0.0–1.0 and mapped to afplay's 0–255 range.
  Future<void> _play(String soundName, {double volume = 1.0}) async {
    final path = '/System/Library/Sounds/$soundName.aiff';
    final file = File(path);
    if (!file.existsSync()) return;

    // afplay volume: 0 = silent, 1 = normal. We pass it directly.
    final clampedVolume = volume.clamp(0.0, 1.0);
    try {
      await Process.run('afplay', ['-v', '$clampedVolume', path]);
    } on ProcessException {
      // Silently ignore – sound is non-critical.
    }
  }

  @override
  Future<void> playRecordingStart({double volume = 1.0}) =>
      _play('Tink', volume: volume);

  @override
  Future<void> playRecordingStop({double volume = 1.0}) =>
      _play('Pop', volume: volume);

  @override
  Future<void> playTranscriptionComplete({double volume = 1.0}) =>
      _play('Glass', volume: volume);

  @override
  void dispose() {
    // No resources to release for Process.run approach.
  }
}
