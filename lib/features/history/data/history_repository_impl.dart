import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/features/history/domain/history_repository.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';

/// [HistoryRepository] backed by [SharedPreferences].
///
/// Entries are stored as a JSON-encoded list under a single key.
/// The list is capped at [maxEntries]; oldest entries are pruned on [add].
class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  static const _key = 'transcription_history';
  static const maxEntries = 100;

  final SharedPreferences _prefs;

  @override
  Future<List<TranscriptionEntry>> getAll() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    final entries = list.map(TranscriptionEntry.fromJson).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  @override
  Future<void> add(TranscriptionEntry entry) async {
    final entries = await getAll();
    entries.insert(0, entry);

    // Prune to maxEntries.
    final trimmed = entries.length > maxEntries
        ? entries.sublist(0, maxEntries)
        : entries;

    await _prefs.setString(
      _key,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> delete(String id) async {
    final entries = await getAll();
    entries.removeWhere((e) => e.id == id);
    await _prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}
