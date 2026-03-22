import 'package:duckmouth/features/history/domain/transcription_entry.dart';

/// Abstract interface for transcription-history persistence.
abstract class HistoryRepository {
  /// Return all entries, most-recent first.
  Future<List<TranscriptionEntry>> getAll();

  /// Persist a new entry.
  Future<void> add(TranscriptionEntry entry);

  /// Delete a single entry by [id].
  Future<void> delete(String id);

  /// Remove every entry.
  Future<void> clear();
}
