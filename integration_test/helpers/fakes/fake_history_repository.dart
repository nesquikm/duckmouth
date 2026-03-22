import 'package:duckmouth/features/history/domain/history_repository.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';

/// In-memory history repository for integration tests.
class FakeHistoryRepository implements HistoryRepository {
  final List<TranscriptionEntry> _entries = [];

  @override
  Future<List<TranscriptionEntry>> getAll() async =>
      List.unmodifiable(_entries.reversed.toList());

  @override
  Future<void> add(TranscriptionEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}
