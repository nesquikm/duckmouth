import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';

class MockAccessibilityService extends Mock implements AccessibilityService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClipboardServiceImpl (clipboard operations)', () {
    late ClipboardServiceImpl service;

    setUp(() {
      final mockAccessibility = MockAccessibilityService();
      when(() => mockAccessibility.insertTextWithFallback(any()))
          .thenAnswer((_) async => InsertionMethod.axDirectInsert);
      service = ClipboardServiceImpl(accessibilityService: mockAccessibility);
    });

    testWidgets('copyToClipboard sets clipboard data', (tester) async {
      String? clipboardContent;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<dynamic, dynamic>;
            clipboardContent = args['text'] as String?;
            return null;
          }
          if (call.method == 'Clipboard.getData') {
            if (clipboardContent != null) {
              return <String, dynamic>{'text': clipboardContent};
            }
            return null;
          }
          return null;
        },
      );

      await service.copyToClipboard('Hello, duck!');
      expect(clipboardContent, 'Hello, duck!');
    });

    testWidgets('getClipboard reads clipboard data', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': 'existing content'};
          }
          return null;
        },
      );

      final result = await service.getClipboard();
      expect(result, 'existing content');
    });

    testWidgets('getClipboard returns null when clipboard is empty',
        (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return null;
          }
          return null;
        },
      );

      final result = await service.getClipboard();
      expect(result, isNull);
    });
  });

  group('ClipboardServiceImpl (pasteAtCursor via AccessibilityService)', () {
    late MockAccessibilityService mockAccessibility;
    late ClipboardServiceImpl service;

    setUp(() {
      mockAccessibility = MockAccessibilityService();
      service = ClipboardServiceImpl(accessibilityService: mockAccessibility);
    });

    testWidgets('pasteAtCursor delegates to AccessibilityService',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('test text'))
          .thenAnswer((_) async => InsertionMethod.axDirectInsert);

      await service.pasteAtCursor('test text');

      verify(() => mockAccessibility.insertTextWithFallback('test text'))
          .called(1);
    });

    testWidgets('pasteAtCursor works when fallback reaches CGEvent',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('test text'))
          .thenAnswer((_) async => InsertionMethod.cgEventPaste);

      await service.pasteAtCursor('test text');

      verify(() => mockAccessibility.insertTextWithFallback('test text'))
          .called(1);
    });

    testWidgets('pasteAtCursor works when fallback reaches osascript',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('test text'))
          .thenAnswer((_) async => InsertionMethod.osascript);

      await service.pasteAtCursor('test text');

      verify(() => mockAccessibility.insertTextWithFallback('test text'))
          .called(1);
    });
  });
}
