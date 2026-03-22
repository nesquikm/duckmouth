/// Abstract interface for audio recording operations.
abstract class RecordingRepository {
  /// Start recording audio to a temporary file.
  Future<void> start();

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
