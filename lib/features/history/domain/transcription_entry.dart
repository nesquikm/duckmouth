import 'package:flutter/foundation.dart';

/// A single transcription history entry.
@immutable
class TranscriptionEntry {
  const TranscriptionEntry({
    required this.id,
    required this.rawText,
    required this.timestamp,
    this.processedText,
  });

  /// Deserialise from a JSON map.
  factory TranscriptionEntry.fromJson(Map<String, dynamic> json) {
    return TranscriptionEntry(
      id: json['id'] as String,
      rawText: json['rawText'] as String,
      processedText: json['processedText'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  final String id;
  final String rawText;
  final String? processedText;
  final DateTime timestamp;

  /// The text to show in the UI — prefers processedText when available.
  String get displayText => processedText ?? rawText;

  /// Serialise to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'rawText': rawText,
        'processedText': processedText,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptionEntry &&
          other.id == id &&
          other.rawText == rawText &&
          other.processedText == processedText &&
          other.timestamp == timestamp;

  @override
  int get hashCode => Object.hash(id, rawText, processedText, timestamp);

  @override
  String toString() =>
      'TranscriptionEntry(id: $id, rawText: $rawText, '
      'processedText: $processedText, timestamp: $timestamp)';
}
