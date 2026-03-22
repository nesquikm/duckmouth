import 'package:duckmouth/core/services/accessibility_service.dart';

/// No-op accessibility service that always reports permission granted.
class FakeAccessibilityService implements AccessibilityService {
  @override
  Future<AccessibilityStatus> checkPermission() async =>
      AccessibilityStatus.granted;

  @override
  Future<void> requestPermission() async {}

  @override
  Future<bool> insertText(String text) async => true;

  @override
  Future<bool> pasteViaCGEvent(String text) async => true;

  @override
  Future<InsertionMethod> insertTextWithFallback(String text) async =>
      InsertionMethod.axDirectInsert;
}
