import 'package:record/record.dart' show InputDevice;

import 'package:duckmouth/features/recording/domain/audio_format_config.dart';

/// Abstract interface for audio recording operations.
abstract class RecordingRepository {
  /// Start recording audio to a temporary file.
  ///
  /// If [formatConfig] is provided, it determines the audio format,
  /// sample rate, and bit rate. Otherwise defaults are used.
  /// If [deviceId] is provided, records from that specific input device.
  Future<void> start({AudioFormatConfig? formatConfig, String? deviceId});

  /// List available audio input devices.
  Future<List<InputDevice>> listInputDevices();

  /// Stop recording and return the file path of the recorded audio.
  /// Returns null if no recording was in progress.
  Future<String?> stop();

  /// Check if the app has microphone permission.
  Future<bool> hasPermission();

  /// Request microphone permission from the user.
  Future<void> requestPermission();

  /// Stream that emits the elapsed recording duration periodically.
  Stream<Duration> get durationStream;

  /// Dispose of resources.
  Future<void> dispose();
}
