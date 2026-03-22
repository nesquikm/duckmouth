import 'package:duckmouth/core/services/clipboard_service.dart';

/// Fake clipboard service that captures output text in a buffer for assertion.
class FakeClipboardService implements ClipboardService {
  final List<String> copiedTexts = [];
  final List<String> pastedTexts = [];
  String? _clipboard;

  @override
  Future<void> copyToClipboard(String text) async {
    copiedTexts.add(text);
    _clipboard = text;
  }

  @override
  Future<String?> getClipboard() async => _clipboard;

  @override
  Future<void> pasteAtCursor(String text) async {
    pastedTexts.add(text);
    _clipboard = text;
  }

  /// All output texts (both copied and pasted).
  List<String> get allOutputTexts => [...copiedTexts, ...pastedTexts];

  /// The last output text.
  String? get lastOutput =>
      allOutputTexts.isNotEmpty ? allOutputTexts.last : null;
}
