import 'dart:io';

import 'package:flutter/services.dart';

/// Abstract interface for clipboard operations.
abstract class ClipboardService {
  /// Copy [text] to the system clipboard.
  Future<void> copyToClipboard(String text);

  /// Read the current clipboard contents, if any.
  Future<String?> getClipboard();

  /// Copy [text] to clipboard and simulate Cmd+V to paste at the cursor
  /// position. Uses AppleScript via osascript, which requires macOS
  /// accessibility permissions.
  ///
  /// After pasting, the original clipboard contents are restored.
  Future<void> pasteAtCursor(String text);
}

/// Default implementation backed by Flutter's [Clipboard] and macOS osascript.
class ClipboardServiceImpl implements ClipboardService {
  @override
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  @override
  Future<String?> getClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  @override
  Future<void> pasteAtCursor(String text) async {
    // Clipboard sandwich: save → set → paste → restore.
    final previous = await getClipboard();
    await copyToClipboard(text);

    // Simulate Cmd+V via AppleScript. This requires the app (or Terminal)
    // to have accessibility permissions in System Settings → Privacy &
    // Security → Accessibility.
    await Process.run('osascript', [
      '-e',
      'tell application "System Events" to keystroke "v" using command down',
    ]);

    // Give the target app a moment to process the paste event.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // Restore the previous clipboard contents.
    if (previous != null) {
      await copyToClipboard(previous);
    }
  }
}
