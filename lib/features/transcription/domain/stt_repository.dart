/// Abstract interface for speech-to-text transcription.
abstract class SttRepository {
  /// Transcribe the audio file at [audioFilePath] and return the text.
  Future<String> transcribe(String audioFilePath);
}
