import 'dart:io';

import 'package:flutter/services.dart';

/// Permission status for macOS Accessibility API.
enum AccessibilityStatus {
  granted,
  denied,
  unknown,
}

/// Which insertion method was used by the fallback chain.
enum InsertionMethod {
  /// Direct AX API text insertion — no clipboard touch.
  axDirectInsert,

  /// CGEvent Cmd+V with clipboard sandwich (native, no subprocess).
  cgEventPaste,

  /// osascript Cmd+V — legacy Dart fallback.
  osascript,
}

/// Interface for macOS Accessibility API text insertion.
abstract class AccessibilityService {
  /// Check current Accessibility permission status.
  Future<AccessibilityStatus> checkPermission();

  /// Prompt the user to grant Accessibility permission.
  Future<void> requestPermission();

  /// Attempt to insert text via AX API directly at the cursor.
  /// Returns true if successful.
  Future<bool> insertText(String text);

  /// Attempt to paste text via CGEvent Cmd+V with clipboard sandwich.
  /// Returns true if successful.
  Future<bool> pasteViaCGEvent(String text);

  /// Insert text using the full fallback chain:
  /// AX direct insert → CGEvent Cmd+V → osascript.
  /// Returns which method was used.
  Future<InsertionMethod> insertTextWithFallback(String text);
}

/// Signature for the legacy osascript paste fallback.
typedef OsascriptPasteFn = Future<void> Function(String text);

/// Implementation backed by the `com.duckmouth/text_insertion` platform channel.
class AccessibilityServiceImpl implements AccessibilityService {
  AccessibilityServiceImpl({
    MethodChannel? channel,
    OsascriptPasteFn? osascriptPaste,
  })  : _channel = channel ??
            const MethodChannel('com.duckmouth/text_insertion'),
        _osascriptPaste = osascriptPaste ?? _defaultOsascriptPaste;

  final MethodChannel _channel;
  final OsascriptPasteFn _osascriptPaste;

  @override
  Future<AccessibilityStatus> checkPermission() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'checkAccessibilityPermission',
      );
      final status = result?['status'] as String?;
      return switch (status) {
        'granted' => AccessibilityStatus.granted,
        'denied' => AccessibilityStatus.denied,
        _ => AccessibilityStatus.unknown,
      };
    } on Exception {
      return AccessibilityStatus.unknown;
    }
  }

  @override
  Future<void> requestPermission() async {
    await _channel.invokeMethod<void>('requestAccessibilityPermission');
  }

  @override
  Future<bool> insertText(String text) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'insertTextViaAccessibility',
        {'text': text},
      );
      return result?['success'] == true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> pasteViaCGEvent(String text) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'pasteViaCGEvent',
        {'text': text},
      );
      return result?['success'] == true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<InsertionMethod> insertTextWithFallback(String text) async {
    // 1. Try AX direct insert (no clipboard touch).
    if (await insertText(text)) {
      return InsertionMethod.axDirectInsert;
    }

    // 2. Try CGEvent Cmd+V (clipboard sandwich, no subprocess).
    if (await pasteViaCGEvent(text)) {
      return InsertionMethod.cgEventPaste;
    }

    // 3. Legacy osascript fallback.
    await _osascriptPaste(text);
    return InsertionMethod.osascript;
  }
}

/// Default osascript clipboard sandwich paste implementation.
Future<void> _defaultOsascriptPaste(String text) async {
  // Save current clipboard.
  final previous = await Clipboard.getData(Clipboard.kTextPlain);

  // Set clipboard to new text.
  await Clipboard.setData(ClipboardData(text: text));

  // Simulate Cmd+V via AppleScript.
  await Process.run('osascript', [
    '-e',
    'tell application "System Events" to keystroke "v" using command down',
  ]);

  // Wait for paste to be processed.
  await Future<void>.delayed(const Duration(milliseconds: 200));

  // Restore previous clipboard.
  if (previous?.text != null) {
    await Clipboard.setData(ClipboardData(text: previous!.text!));
  }
}
