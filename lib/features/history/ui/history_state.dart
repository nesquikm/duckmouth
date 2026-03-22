import 'package:flutter/foundation.dart';

import 'package:duckmouth/features/history/domain/transcription_entry.dart';

/// Base class for history states.
@immutable
sealed class HistoryState {
  const HistoryState();
}

/// History is being loaded.
class HistoryLoading extends HistoryState {
  const HistoryLoading();

  @override
  bool operator ==(Object other) => other is HistoryLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// History loaded successfully.
class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.entries);

  final List<TranscriptionEntry> entries;

  @override
  bool operator ==(Object other) =>
      other is HistoryLoaded &&
      listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hashAll(entries);
}

/// An error occurred loading history.
class HistoryError extends HistoryState {
  const HistoryError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is HistoryError && other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}
