import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/core/services/accessibility_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.duckmouth/text_insertion');
  late AccessibilityServiceImpl service;
  late List<MethodCall> log;
  late List<String> osascriptCalls;

  setUp(() {
    log = [];
    osascriptCalls = [];
    service = AccessibilityServiceImpl(
      osascriptPaste: (text) async {
        osascriptCalls.add(text);
      },
    );
  });

  void setUpMockChannel(
    TestWidgetsFlutterBinding binding, {
    Map<String, dynamic>? checkResult,
    Map<String, dynamic>? insertResult,
    Map<String, dynamic>? pasteResult,
  }) {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async {
        log.add(call);
        switch (call.method) {
          case 'checkAccessibilityPermission':
            return checkResult ?? {'status': 'denied'};
          case 'requestAccessibilityPermission':
            return null;
          case 'insertTextViaAccessibility':
            return insertResult ?? {'success': false, 'error': 'mock fail'};
          case 'pasteViaCGEvent':
            return pasteResult ?? {'success': true};
          default:
            return null;
        }
      },
    );
  }

  group('checkPermission', () {
    testWidgets('returns granted when platform reports granted',
        (tester) async {
      setUpMockChannel(
        tester.binding,
        checkResult: {'status': 'granted'},
      );

      final status = await service.checkPermission();
      expect(status, AccessibilityStatus.granted);
    });

    testWidgets('returns denied when platform reports denied',
        (tester) async {
      setUpMockChannel(
        tester.binding,
        checkResult: {'status': 'denied'},
      );

      final status = await service.checkPermission();
      expect(status, AccessibilityStatus.denied);
    });

    testWidgets('returns unknown on platform error', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async {
          if (call.method == 'checkAccessibilityPermission') {
            throw PlatformException(code: 'ERROR');
          }
          return null;
        },
      );

      final status = await service.checkPermission();
      expect(status, AccessibilityStatus.unknown);
    });
  });

  group('requestPermission', () {
    testWidgets('invokes platform method', (tester) async {
      setUpMockChannel(tester.binding);

      await service.requestPermission();
      expect(
        log.map((c) => c.method),
        contains('requestAccessibilityPermission'),
      );
    });
  });

  group('insertText', () {
    testWidgets('returns true when AX insert succeeds', (tester) async {
      setUpMockChannel(
        tester.binding,
        insertResult: {'success': true},
      );

      final result = await service.insertText('hello');
      expect(result, isTrue);
      expect(log.first.method, 'insertTextViaAccessibility');
      expect(
        (log.first.arguments as Map)['text'],
        'hello',
      );
    });

    testWidgets('returns false when AX insert fails', (tester) async {
      setUpMockChannel(
        tester.binding,
        insertResult: {'success': false, 'error': 'not supported'},
      );

      final result = await service.insertText('hello');
      expect(result, isFalse);
    });
  });

  group('pasteViaCGEvent', () {
    testWidgets('calls platform method with text', (tester) async {
      setUpMockChannel(
        tester.binding,
        pasteResult: {'success': true},
      );

      final result = await service.pasteViaCGEvent('world');
      expect(result, isTrue);
      expect(log.first.method, 'pasteViaCGEvent');
      expect(
        (log.first.arguments as Map)['text'],
        'world',
      );
    });

    testWidgets('returns false on failure', (tester) async {
      setUpMockChannel(
        tester.binding,
        pasteResult: {'success': false, 'error': 'failed'},
      );

      final result = await service.pasteViaCGEvent('world');
      expect(result, isFalse);
    });
  });

  group('insertTextWithFallback', () {
    testWidgets('uses AX insert when it succeeds — no further calls',
        (tester) async {
      setUpMockChannel(
        tester.binding,
        insertResult: {'success': true},
      );

      final method = await service.insertTextWithFallback('hi');
      expect(method, InsertionMethod.axDirectInsert);
      expect(log.length, 1);
      expect(log.first.method, 'insertTextViaAccessibility');
    });

    testWidgets('falls back to CGEvent when AX fails', (tester) async {
      setUpMockChannel(
        tester.binding,
        insertResult: {'success': false, 'error': 'nope'},
        pasteResult: {'success': true},
      );

      final method = await service.insertTextWithFallback('hi');
      expect(method, InsertionMethod.cgEventPaste);
      expect(log.length, 2);
      expect(log[0].method, 'insertTextViaAccessibility');
      expect(log[1].method, 'pasteViaCGEvent');
    });

    testWidgets('falls back to osascript when both AX and CGEvent fail',
        (tester) async {
      setUpMockChannel(
        tester.binding,
        insertResult: {'success': false, 'error': 'nope'},
        pasteResult: {'success': false, 'error': 'also nope'},
      );

      final method = await service.insertTextWithFallback('hi');
      expect(method, InsertionMethod.osascript);
      // AX + CGEvent = 2 platform calls; osascript is handled in Dart
      expect(log.length, 2);
      expect(osascriptCalls, ['hi']);
    });
  });
}
