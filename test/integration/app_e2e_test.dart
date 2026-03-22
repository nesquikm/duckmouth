import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';

import '../../integration_test/helpers/fakes/fake_post_processing_repository.dart';
import '../../integration_test/helpers/fakes/fake_stt_repository.dart';
import '../../integration_test/helpers/test_harness.dart';

/// Helper: record and stop, then let the full async cascade complete.
Future<void> _recordAndWait(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.byIcon(Icons.mic));
  });
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    await tester.tap(find.byIcon(Icons.stop));
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

void main() {
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

      expect(find.text('Duckmouth'), findsOneWidget);
      expect(find.text('Ready to record'), findsOneWidget);

      await _recordAndWait(tester);

      // Transcription result should be displayed.
      expect(
        find.text('Hello world, this is a test transcription.'),
        findsOneWidget,
      );

      // Post-processing result should be displayed.
      expect(
        find.text('Hello world, this is a processed transcription.'),
        findsOneWidget,
      );

      // Verify output was sent to clipboard.
      expect(
        harness.clipboardService.allOutputTexts,
        contains('Hello world, this is a processed transcription.'),
      );

      // Navigate to history and verify entry exists.
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(
        find.textContaining('Hello world, this is a processed'),
        findsWidgets,
      );

      await harness.tearDown();
    });

    testWidgets('STT error → retry → success', (tester) async {
      final harness = TestHarness(
        sttRepository: FakeSttRepository(failCount: 1),
        postProcessingConfig: const PostProcessingConfig(enabled: false),
      );
      harness.setUp();

      await tester.pumpWidget(const DuckmouthApp());
      await tester.pumpAndSettle();

      await _recordAndWait(tester);

      // Error should be shown.
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap "Try Again" — resets state.
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      // Record again (second call will succeed).
      await _recordAndWait(tester);

      // Transcription should succeed.
      expect(
        find.text('Hello world, this is a test transcription.'),
        findsOneWidget,
      );

      await harness.tearDown();
    });

    testWidgets('post-processing error → raw text shown → retry → success',
        (tester) async {
      final harness = TestHarness(
        postProcessingRepository: FakePostProcessingRepository(failCount: 1),
        postProcessingConfig: const PostProcessingConfig(
          enabled: true,
          prompt: 'Fix grammar',
        ),
      );
      harness.setUp();

      await tester.pumpWidget(const DuckmouthApp());
      await tester.pumpAndSettle();

      await _recordAndWait(tester);

      // Raw transcription should be visible.
      expect(
        find.text('Hello world, this is a test transcription.'),
        findsOneWidget,
      );

      // Post-processing error should be shown.
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);

      // Tap "Retry Processing".
      await tester.runAsync(() async {
        await tester.tap(find.text('Retry Processing'));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      // Post-processing should succeed now.
      expect(
        find.text('Hello world, this is a processed transcription.'),
        findsOneWidget,
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

      // Raw text should be displayed.
      expect(
        find.text('Hello world, this is a test transcription.'),
        findsOneWidget,
      );

      // No "Processed:" label.
      expect(find.text('Processed:'), findsNothing);

      // Verify raw text was sent to clipboard.
      expect(
        harness.clipboardService.allOutputTexts,
        contains('Hello world, this is a test transcription.'),
      );

      await harness.tearDown();
    });
  });
}
