import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

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

  /// Insert text using the fallback chain:
  /// AX direct insert → CGEvent Cmd+V.
  /// Returns which method was used. Throws if both methods fail.
  Future<InsertionMethod> insertTextWithFallback(String text);
}

/// Implementation backed by the `com.duckmouth/text_insertion` platform channel.
class AccessibilityServiceImpl implements AccessibilityService {
  static final _log = Logger('AccessibilityService');

  AccessibilityServiceImpl({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.duckmouth/text_insertion');

  final MethodChannel _channel;

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
      _log.fine('Text inserted via AX direct insert');
      return InsertionMethod.axDirectInsert;
    }

    // 2. Try CGEvent Cmd+V (clipboard sandwich, no subprocess).
    if (await pasteViaCGEvent(text)) {
      _log.fine('Text inserted via CGEvent paste');
      return InsertionMethod.cgEventPaste;
    }

    // Both methods failed.
    _log.warning('All text insertion methods failed');
    throw const AccessibilityInsertionException(
      'Could not insert text — both AX and CGEvent methods failed.',
    );
  }
}

/// Exception thrown when all text insertion methods fail.
class AccessibilityInsertionException implements Exception {
  const AccessibilityInsertionException(this.message);

  final String message;

  @override
  String toString() => 'AccessibilityInsertionException: $message';
}
