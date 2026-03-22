import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/features/history/data/history_repository_impl.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';

void main() {
  late SharedPreferences prefs;
  late HistoryRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = HistoryRepositoryImpl(prefs: prefs);
  });

  group('HistoryRepositoryImpl', () {
    test('getAll returns empty list when no data stored', () async {
      final entries = await repo.getAll();
      expect(entries, isEmpty);
    });

    test('add persists an entry and getAll retrieves it', () async {
      final entry = TranscriptionEntry(
        id: '1',
        rawText: 'hello',
        timestamp: DateTime(2026, 3, 22, 10, 0),
      );

      await repo.add(entry);
      final entries = await repo.getAll();

      expect(entries, hasLength(1));
      expect(entries.first.id, '1');
      expect(entries.first.rawText, 'hello');
    });

    test('entries are returned most-recent first', () async {
      final older = TranscriptionEntry(
        id: '1',
        rawText: 'older',
        timestamp: DateTime(2026, 3, 22, 9, 0),
      );
      final newer = TranscriptionEntry(
        id: '2',
        rawText: 'newer',
        timestamp: DateTime(2026, 3, 22, 10, 0),
      );

      await repo.add(older);
      await repo.add(newer);

      final entries = await repo.getAll();
      expect(entries.first.id, '2');
      expect(entries.last.id, '1');
    });

    test('delete removes entry by id', () async {
      final entry = TranscriptionEntry(
        id: '1',
        rawText: 'hello',
        timestamp: DateTime(2026, 3, 22, 10, 0),
      );

      await repo.add(entry);
      await repo.delete('1');

      final entries = await repo.getAll();
      expect(entries, isEmpty);
    });

    test('clear removes all entries', () async {
      for (var i = 0; i < 3; i++) {
        await repo.add(TranscriptionEntry(
          id: '$i',
          rawText: 'text $i',
          timestamp: DateTime(2026, 3, 22, i),
        ));
      }

      await repo.clear();
      final entries = await repo.getAll();
      expect(entries, isEmpty);
    });

    test('add prunes to maxEntries', () async {
      for (var i = 0; i < HistoryRepositoryImpl.maxEntries + 10; i++) {
        await repo.add(TranscriptionEntry(
          id: '$i',
          rawText: 'text $i',
          timestamp: DateTime(2026, 1, 1, 0, i),
        ));
      }

      final entries = await repo.getAll();
      expect(entries.length, HistoryRepositoryImpl.maxEntries);
    });

    test('persists processedText', () async {
      final entry = TranscriptionEntry(
        id: '1',
        rawText: 'raw',
        processedText: 'processed',
        timestamp: DateTime(2026, 3, 22, 10, 0),
      );

      await repo.add(entry);
      final entries = await repo.getAll();

      expect(entries.first.processedText, 'processed');
    });
  });
}
