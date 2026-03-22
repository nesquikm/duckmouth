import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/history/domain/transcription_entry.dart';

void main() {
  final timestamp = DateTime(2026, 3, 22, 10, 30);

  group('TranscriptionEntry', () {
    test('displayText returns processedText when available', () {
      final entry = TranscriptionEntry(
        id: '1',
        rawText: 'raw',
        processedText: 'processed',
        timestamp: timestamp,
      );
      expect(entry.displayText, 'processed');
    });

    test('displayText falls back to rawText when processedText is null', () {
      final entry = TranscriptionEntry(
        id: '1',
        rawText: 'raw',
        timestamp: timestamp,
      );
      expect(entry.displayText, 'raw');
    });

    test('toJson and fromJson round-trip correctly', () {
      final entry = TranscriptionEntry(
        id: 'abc-123',
        rawText: 'hello world',
        processedText: 'Hello, world!',
        timestamp: timestamp,
      );
      final json = entry.toJson();
      final restored = TranscriptionEntry.fromJson(json);

      expect(restored, entry);
      expect(restored.id, 'abc-123');
      expect(restored.rawText, 'hello world');
      expect(restored.processedText, 'Hello, world!');
      expect(restored.timestamp, timestamp);
    });

    test('toJson omits processedText as null', () {
      final entry = TranscriptionEntry(
        id: '1',
        rawText: 'raw',
        timestamp: timestamp,
      );
      final json = entry.toJson();
      expect(json['processedText'], isNull);

      final restored = TranscriptionEntry.fromJson(json);
      expect(restored.processedText, isNull);
      expect(restored, entry);
    });

    test('equality works correctly', () {
      final a = TranscriptionEntry(
        id: '1',
        rawText: 'raw',
        timestamp: timestamp,
      );
      final b = TranscriptionEntry(
        id: '1',
        rawText: 'raw',
        timestamp: timestamp,
      );
      final c = TranscriptionEntry(
        id: '2',
        rawText: 'raw',
        timestamp: timestamp,
      );

      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });
}
