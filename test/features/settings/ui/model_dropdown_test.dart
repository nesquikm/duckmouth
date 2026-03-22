import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/api/models_client.dart';
import 'package:duckmouth/features/settings/ui/model_dropdown.dart';

class MockModelsClient extends Mock implements ModelsClient {}

void main() {
  late MockModelsClient mockClient;
  late TextEditingController controller;

  setUp(() {
    mockClient = MockModelsClient();
    controller = TextEditingController(text: 'whisper-1');
  });

  tearDown(() {
    controller.dispose();
  });

  Widget buildWidget({
    String baseUrl = 'https://api.openai.com',
    String apiKey = 'test-key',
    ModelType modelType = ModelType.stt,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ModelDropdown(
          modelsClient: mockClient,
          baseUrl: baseUrl,
          apiKey: apiKey,
          modelType: modelType,
          controller: controller,
          enabled: enabled,
        ),
      ),
    );
  }

  testWidgets('shows loading indicator while fetching', (tester) async {
    final completer = Completer<List<String>>();
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildWidget());
    await tester.pump(); // Trigger build after initState

    // Should show a CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the future to clean up the pending timer.
    completer.complete(['whisper-1']);
    await tester.pumpAndSettle();
  });

  testWidgets('shows dropdown with models on success', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => ['whisper-1', 'whisper-large-v3-turbo']);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('falls back to text field on fetch failure', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => []);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Could not load models — type manually'), findsOneWidget);
  });

  testWidgets('shows text field when baseUrl is empty', (tester) async {
    await tester.pumpWidget(buildWidget(baseUrl: ''));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    verifyNever(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        ));
  });

  testWidgets('shows text field when apiKey is empty', (tester) async {
    await tester.pumpWidget(buildWidget(apiKey: ''));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    verifyNever(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        ));
  });

  testWidgets('refreshes when baseUrl changes', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: 'https://api.openai.com',
          apiKey: 'test-key',
        )).thenAnswer((_) async => ['whisper-1']);

    when(() => mockClient.fetchModels(
          baseUrl: 'https://api.groq.com/openai',
          apiKey: 'test-key',
        )).thenAnswer((_) async => ['whisper-large-v3-turbo']);

    // Build with first URL.
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    verify(() => mockClient.fetchModels(
          baseUrl: 'https://api.openai.com',
          apiKey: 'test-key',
        )).called(1);

    // Rebuild with new URL.
    await tester.pumpWidget(buildWidget(baseUrl: 'https://api.groq.com/openai'));
    await tester.pumpAndSettle();

    verify(() => mockClient.fetchModels(
          baseUrl: 'https://api.groq.com/openai',
          apiKey: 'test-key',
        )).called(1);
  });

  testWidgets('refreshes when apiKey changes', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: 'key-1',
        )).thenAnswer((_) async => ['whisper-1']);

    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: 'key-2',
        )).thenAnswer((_) async => ['whisper-1', 'whisper-large-v3-turbo']);

    await tester.pumpWidget(buildWidget(apiKey: 'key-1'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(buildWidget(apiKey: 'key-2'));
    await tester.pumpAndSettle();

    verify(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: 'key-2',
        )).called(1);
  });

  testWidgets('preserves current model if still in list', (tester) async {
    controller.text = 'whisper-1';
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => ['whisper-1', 'whisper-large-v3-turbo']);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // The dropdown should have whisper-1 selected.
    expect(find.text('whisper-1'), findsOneWidget);
  });

  testWidgets('free-text fallback allows typing', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => []);

    controller.text = '';
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'my-custom-model');
    expect(controller.text, 'my-custom-model');
  });
}
