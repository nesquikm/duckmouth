import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'package:duckmouth/core/services/accessibility_service.dart';

/// Abstract interface for clipboard operations.
abstract class ClipboardService {
  /// Copy [text] to the system clipboard.
  Future<void> copyToClipboard(String text);

  /// Read the current clipboard contents, if any.
  Future<String?> getClipboard();

  /// Insert [text] at the cursor position using the Accessibility API
  /// fallback chain: AX direct insert → CGEvent Cmd+V → osascript.
  Future<void> pasteAtCursor(String text);
}

/// Default implementation backed by Flutter's [Clipboard] and
/// [AccessibilityService] for paste-at-cursor.
class ClipboardServiceImpl implements ClipboardService {
  static final _log = Logger('ClipboardService');

  ClipboardServiceImpl({
    required AccessibilityService accessibilityService,
  }) : _accessibilityService = accessibilityService;

  final AccessibilityService _accessibilityService;

  @override
  Future<void> copyToClipboard(String text) async {
    _log.fine('Copy to clipboard (${text.length} chars)');
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Future<String?> getClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  @override
  Future<void> pasteAtCursor(String text) async {
    _log.fine('Paste at cursor (${text.length} chars)');
    await _accessibilityService.insertTextWithFallback(text);
  }
}
