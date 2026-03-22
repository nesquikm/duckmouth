import 'dart:async';

import 'package:record/record.dart' show InputDevice;

import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';

/// Fake recording repository that simulates mic capture with deterministic
/// behavior. Returns a canned file path immediately on stop.
class FakeRecordingRepository implements RecordingRepository {
  FakeRecordingRepository({
    this.audioFilePath = '/tmp/fake_recording.wav',
    this.shouldFailOnStart = false,
  });

  final String audioFilePath;
  final bool shouldFailOnStart;

  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  @override
  Future<void> start({AudioFormatConfig? formatConfig, String? deviceId}) async {
    if (shouldFailOnStart) {
      throw Exception('Fake recording error');
    }
    // Emit a single duration event synchronously.
    _durationController.add(const Duration(milliseconds: 100));
  }

  @override
  Future<String?> stop() async {
    return audioFilePath;
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> requestPermission() async {}

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Future<List<InputDevice>> listInputDevices() async => [];

  @override
  Future<void> dispose() async {
    await _durationController.close();
  }
}
