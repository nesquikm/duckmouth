// History CRUD integration test. Mirrors test/integration/history_e2e_test.dart
// Run with: fvm flutter test integration_test/history_test.dart -d macos

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';

import 'helpers/test_harness.dart';

/// Helper: record and stop, then pump until settled.
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

  group('E2E: History', () {
    testWidgets('clear all history', (tester) async {
      final harness = TestHarness(
        postProcessingConfig: const PostProcessingConfig(enabled: false),
      );
      harness.setUp();

      await tester.pumpWidget(const DuckmouthApp());
      await tester.pumpAndSettle();

      await _recordAndWait(tester);

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      expect(find.text('Clear history'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('No transcriptions yet.'), findsOneWidget);

      await harness.tearDown();
    });
  });
}
