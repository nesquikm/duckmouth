import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/core/services/clipboard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClipboardServiceImpl service;

  setUp(() {
    service = ClipboardServiceImpl();
  });

  group('ClipboardServiceImpl', () {
    testWidgets('copyToClipboard sets clipboard data', (tester) async {
      // Set up a mock clipboard handler.
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
}
