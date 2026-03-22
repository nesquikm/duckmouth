import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';

import '../../integration_test/helpers/test_harness.dart';

/// Helper: record and stop, then let async cascade complete.
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
  group('E2E: History CRUD', () {
    testWidgets('complete transcription → view in history → delete',
        (tester) async {
      final harness = TestHarness(
        postProcessingConfig: const PostProcessingConfig(enabled: false),
      );
      harness.setUp();

      await tester.pumpWidget(const DuckmouthApp());
      await tester.pumpAndSettle();

      await _recordAndWait(tester);

      // Navigate to history.
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(
        find.textContaining('Hello world, this is a test'),
        findsOneWidget,
      );

      // Swipe to delete.
      await tester.drag(
        find.textContaining('Hello world, this is a test'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Entry should be removed.
      expect(find.text('No transcriptions yet.'), findsOneWidget);

      await harness.tearDown();
    });

    testWidgets('clear all history', (tester) async {
      final harness = TestHarness(
        postProcessingConfig: const PostProcessingConfig(enabled: false),
      );
      harness.setUp();

      await tester.pumpWidget(const DuckmouthApp());
      await tester.pumpAndSettle();

      await _recordAndWait(tester);

      // Navigate to history.
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Tap clear history button.
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      // Confirm dialog.
      expect(find.text('Clear history'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // History should be empty.
      expect(find.text('No transcriptions yet.'), findsOneWidget);

      await harness.tearDown();
    });
  });
}
