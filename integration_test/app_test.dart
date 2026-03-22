// These integration tests require IntegrationTestWidgetsFlutterBinding and
// must be run on a macOS device: `fvm flutter test integration_test/ -d macos`
//
// For the same tests runnable without a device, see test/integration/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';

import 'helpers/test_harness.dart';

/// Helper: record and stop, then let the full async cascade complete.
Future<void> _recordAndWait(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.mic));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.byIcon(Icons.stop));
  await tester.pump();
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: App flow', () {
    testWidgets(
        'happy path: record → transcribe → post-process → output → history',
        (tester) async {
      final harness = TestHarness(
        postProcessingConfig: const PostProcessingConfig(
          enabled: true,
          prompt: 'Fix grammar',
        ),
      );
      harness.setUp();

      await tester.pumpWidget(const DuckmouthApp());
      await tester.pumpAndSettle();

      await _recordAndWait(tester);

      expect(
        find.text('Hello world, this is a test transcription.'),
        findsOneWidget,
      );
      expect(
        find.text('Hello world, this is a processed transcription.'),
        findsOneWidget,
      );
      expect(
        harness.clipboardService.allOutputTexts,
        contains('Hello world, this is a processed transcription.'),
      );

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(
        find.textContaining('Hello world, this is a processed'),
        findsWidgets,
      );

      await harness.tearDown();
    });

    testWidgets('post-processing disabled → raw text output', (tester) async {
      final harness = TestHarness(
        postProcessingConfig: const PostProcessingConfig(enabled: false),
      );
      harness.setUp();

      await tester.pumpWidget(const DuckmouthApp());
      await tester.pumpAndSettle();

      await _recordAndWait(tester);

      expect(
        find.text('Hello world, this is a test transcription.'),
        findsOneWidget,
      );
      expect(find.text('Processed:'), findsNothing);
      expect(
        harness.clipboardService.allOutputTexts,
        contains('Hello world, this is a test transcription.'),
      );

      await harness.tearDown();
    });
  });
}
