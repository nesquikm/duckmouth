import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

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

/// macOS implementation that plays system sounds via NSSound platform channel.
class SoundServiceImpl implements SoundService {
  static final _log = Logger('SoundService');

  SoundServiceImpl({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('com.duckmouth/sound');

  final MethodChannel _channel;

  /// Play a macOS system sound by name via the native platform channel.
  Future<void> _play(String soundName, {double volume = 1.0}) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    try {
      await _channel.invokeMethod<Map>('playSound', {
        'name': soundName,
        'volume': clampedVolume,
      });
    } on Exception catch (e, st) {
      _log.fine('Sound playback failed: $soundName', e, st);
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
    // No resources to release for platform channel approach.
  }
}
