import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/features/history/domain/history_repository.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';
import 'package:duckmouth/features/history/ui/history_state.dart';

/// Cubit that manages transcription history.
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required HistoryRepository repository})
      : _repository = repository,
        super(const HistoryLoading());

  final HistoryRepository _repository;

  /// Load all history entries from storage.
  Future<void> loadHistory() async {
    _tryEmit(const HistoryLoading());
    try {
      final entries = await _repository.getAll();
      _tryEmit(HistoryLoaded(entries));
    } on Exception catch (e) {
      _tryEmit(HistoryError(e.toString()));
    }
  }

  /// Add a new entry and refresh the loaded list.
  Future<void> addEntry(TranscriptionEntry entry) async {
    try {
      await _repository.add(entry);
      final entries = await _repository.getAll();
      _tryEmit(HistoryLoaded(entries));
    } on Exception catch (e) {
      _tryEmit(HistoryError(e.toString()));
    }
  }

  /// Delete a single entry by its [id].
  Future<void> deleteEntry(String id) async {
    try {
      await _repository.delete(id);
      final entries = await _repository.getAll();
      _tryEmit(HistoryLoaded(entries));
    } on Exception catch (e) {
      _tryEmit(HistoryError(e.toString()));
    }
  }

  /// Clear all history.
  Future<void> clearHistory() async {
    try {
      await _repository.clear();
      _tryEmit(const HistoryLoaded([]));
    } on Exception catch (e) {
      _tryEmit(HistoryError(e.toString()));
    }
  }

  void _tryEmit(HistoryState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
