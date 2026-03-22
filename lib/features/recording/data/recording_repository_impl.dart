import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';

import '../domain/audio_format_config.dart';
import '../domain/recording_repository.dart';

/// Concrete implementation of [RecordingRepository] using the record package.
class RecordingRepositoryImpl implements RecordingRepository {
  RecordingRepositoryImpl({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  Timer? _durationTimer;
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  DateTime? _recordingStartTime;

  @override
  Future<void> start({AudioFormatConfig? formatConfig}) async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw RecordingPermissionException(
        'Microphone permission not granted',
      );
    }

    final config = formatConfig ?? const AudioFormatConfig();
    final format = config.effectiveFormat;
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${tempDir.path}/duckmouth_recording_$timestamp.${format.extension}';

    await _recorder.start(
      RecordConfig(
        encoder: format.encoder,
        sampleRate: config.effectiveSampleRate,
        bitRate: config.effectiveBitRate ?? 128000,
        numChannels: 1,
      ),
      path: filePath,
    );

    _recordingStartTime = DateTime.now();
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (_recordingStartTime != null) {
          final elapsed = DateTime.now().difference(_recordingStartTime!);
          _durationController.add(elapsed);
        }
      },
    );
  }

  @override
  Future<String?> stop() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _recordingStartTime = null;

    final path = await _recorder.stop();
    return path;
  }

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> requestPermission() async {
    await _recorder.hasPermission();
  }

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Future<void> dispose() async {
    _durationTimer?.cancel();
    await _durationController.close();
    await _recorder.dispose();
  }
}

/// Exception thrown when microphone permission is not granted.
class RecordingPermissionException implements Exception {
  const RecordingPermissionException(this.message);

  final String message;

  @override
  String toString() => 'RecordingPermissionException: $message';
}
