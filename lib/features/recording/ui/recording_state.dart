import 'package:flutter/foundation.dart';

/// Base class for recording states.
@immutable
sealed class RecordingState {
  const RecordingState();
}

/// Initial idle state — no recording in progress.
class RecordingIdle extends RecordingState {
  const RecordingIdle();

  @override
  bool operator ==(Object other) => other is RecordingIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Recording is in progress with elapsed duration.
class RecordingInProgress extends RecordingState {
  const RecordingInProgress(this.duration);

  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is RecordingInProgress && other.duration == duration;

  @override
  int get hashCode => Object.hash(runtimeType, duration);
}

/// Recording completed with the file path to the audio.
class RecordingComplete extends RecordingState {
  const RecordingComplete(this.filePath);

  final String filePath;

  @override
  bool operator ==(Object other) =>
      other is RecordingComplete && other.filePath == filePath;

  @override
  int get hashCode => Object.hash(runtimeType, filePath);
}

/// An error occurred during recording.
class RecordingError extends RecordingState {
  const RecordingError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is RecordingError && other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
