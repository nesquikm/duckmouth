import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/history/domain/transcription_entry.dart';
import 'package:duckmouth/features/history/ui/history_state.dart';

void main() {
  group('HistoryState', () {
    test('HistoryLoading equality', () {
      expect(const HistoryLoading(), const HistoryLoading());
    });

    test('HistoryLoaded equality with same entries', () {
      final entries = [
        TranscriptionEntry(
          id: '1',
          rawText: 'hi',
          timestamp: DateTime(2026, 1, 1),
        ),
      ];
      expect(HistoryLoaded(entries), HistoryLoaded(entries));
    });

    test('HistoryLoaded inequality with different entries', () {
      final a = HistoryLoaded([
        TranscriptionEntry(
          id: '1',
          rawText: 'hi',
          timestamp: DateTime(2026, 1, 1),
        ),
      ]);
      final b = HistoryLoaded([
        TranscriptionEntry(
          id: '2',
          rawText: 'bye',
          timestamp: DateTime(2026, 1, 1),
        ),
      ]);
      expect(a, isNot(b));
    });

    test('HistoryError equality', () {
      expect(const HistoryError('oops'), const HistoryError('oops'));
      expect(const HistoryError('oops'), isNot(const HistoryError('nope')));
    });
  });
}
