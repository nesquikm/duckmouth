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
      when(() => mockAccessibility.insertTextWithFallback('test text '))
          .thenAnswer((_) async => InsertionMethod.axDirectInsert);

      await service.pasteAtCursor('test text');

      verify(() => mockAccessibility.insertTextWithFallback('test text '))
          .called(1);
    });

    testWidgets('pasteAtCursor works when fallback reaches CGEvent',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('test text '))
          .thenAnswer((_) async => InsertionMethod.cgEventPaste);

      await service.pasteAtCursor('test text');

      verify(() => mockAccessibility.insertTextWithFallback('test text '))
          .called(1);
    });

    testWidgets('pasteAtCursor propagates exception when all methods fail',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('test text '))
          .thenThrow(
        const AccessibilityInsertionException('all methods failed'),
      );

      expect(
        () => service.pasteAtCursor('test text'),
        throwsA(isA<AccessibilityInsertionException>()),
      );
    });

    testWidgets('pasteAtCursor appends trailing space to text',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('hello '))
          .thenAnswer((_) async => InsertionMethod.axDirectInsert);

      await service.pasteAtCursor('hello');

      verify(() => mockAccessibility.insertTextWithFallback('hello '))
          .called(1);
    });

    testWidgets('pasteAtCursor does not double-space text ending with space',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('hello '))
          .thenAnswer((_) async => InsertionMethod.axDirectInsert);

      await service.pasteAtCursor('hello ');

      verify(() => mockAccessibility.insertTextWithFallback('hello '))
          .called(1);
    });

    testWidgets('pasteAtCursor does not add space after newline',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('hello\n'))
          .thenAnswer((_) async => InsertionMethod.axDirectInsert);

      await service.pasteAtCursor('hello\n');

      verify(() => mockAccessibility.insertTextWithFallback('hello\n'))
          .called(1);
    });

    testWidgets('pasteAtCursor does not add space after tab',
        (tester) async {
      when(() => mockAccessibility.insertTextWithFallback('hello\t'))
          .thenAnswer((_) async => InsertionMethod.axDirectInsert);

      await service.pasteAtCursor('hello\t');

      verify(() => mockAccessibility.insertTextWithFallback('hello\t'))
          .called(1);
    });
  });

  group('ClipboardServiceImpl (copyToClipboard not affected by trailing space)',
      () {
    late ClipboardServiceImpl service;

    setUp(() {
      final mockAccessibility = MockAccessibilityService();
      service = ClipboardServiceImpl(accessibilityService: mockAccessibility);
    });

    testWidgets('copyToClipboard does not append trailing space',
        (tester) async {
      String? clipboardContent;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<dynamic, dynamic>;
            clipboardContent = args['text'] as String?;
            return null;
          }
          return null;
        },
      );

      await service.copyToClipboard('hello');
      expect(clipboardContent, 'hello');
    });
  });
}
