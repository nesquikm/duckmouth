import 'package:flutter/foundation.dart';

/// Base class for transcription states.
@immutable
sealed class TranscriptionState {
  const TranscriptionState();
}

/// No transcription in progress.
class TranscriptionIdle extends TranscriptionState {
  const TranscriptionIdle();

  @override
  bool operator ==(Object other) => other is TranscriptionIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Transcription is in progress.
class TranscriptionLoading extends TranscriptionState {
  const TranscriptionLoading();

  @override
  bool operator ==(Object other) => other is TranscriptionLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Transcription completed successfully.
class TranscriptionSuccess extends TranscriptionState {
  const TranscriptionSuccess(this.text);

  final String text;

  @override
  bool operator ==(Object other) =>
      other is TranscriptionSuccess && other.text == text;

  @override
  int get hashCode => Object.hash(runtimeType, text);
}

/// An error occurred during transcription.
class TranscriptionError extends TranscriptionState {
  const TranscriptionError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is TranscriptionError && other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
