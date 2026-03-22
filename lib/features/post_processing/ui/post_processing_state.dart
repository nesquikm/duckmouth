import 'package:flutter/foundation.dart';

/// Base class for post-processing states.
@immutable
sealed class PostProcessingState {
  const PostProcessingState();
}

/// No post-processing in progress.
class PostProcessingIdle extends PostProcessingState {
  const PostProcessingIdle();

  @override
  bool operator ==(Object other) => other is PostProcessingIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Post-processing is disabled in settings.
class PostProcessingDisabled extends PostProcessingState {
  const PostProcessingDisabled();

  @override
  bool operator ==(Object other) => other is PostProcessingDisabled;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Post-processing is in progress.
class PostProcessingLoading extends PostProcessingState {
  const PostProcessingLoading({required this.rawText});

  final String rawText;

  @override
  bool operator ==(Object other) =>
      other is PostProcessingLoading && other.rawText == rawText;

  @override
  int get hashCode => Object.hash(runtimeType, rawText);
}

/// Post-processing completed successfully.
class PostProcessingSuccess extends PostProcessingState {
  const PostProcessingSuccess({
    required this.rawText,
    required this.processedText,
  });

  final String rawText;
  final String processedText;

  @override
  bool operator ==(Object other) =>
      other is PostProcessingSuccess &&
      other.rawText == rawText &&
      other.processedText == processedText;

  @override
  int get hashCode => Object.hash(runtimeType, rawText, processedText);
}

/// An error occurred during post-processing.
class PostProcessingError extends PostProcessingState {
  const PostProcessingError({
    required this.rawText,
    required this.message,
  });

  final String rawText;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is PostProcessingError &&
      other.rawText == rawText &&
      other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, rawText, message);
}
