import 'package:duckmouth/core/services/sound_service.dart';

/// No-op sound service that records calls for assertion.
class FakeSoundService implements SoundService {
  final List<String> calls = [];

  @override
  Future<void> playRecordingStart({double volume = 1.0}) async {
    calls.add('recordingStart');
  }

  @override
  Future<void> playRecordingStop({double volume = 1.0}) async {
    calls.add('recordingStop');
  }

  @override
  Future<void> playTranscriptionComplete({double volume = 1.0}) async {
    calls.add('transcriptionComplete');
  }

  @override
  void dispose() {}
}
