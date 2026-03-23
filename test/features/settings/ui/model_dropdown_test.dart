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

  testWidgets('always shows TextField (not locked dropdown)', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => ['whisper-1', 'whisper-large-v3-turbo']);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Should always show a TextField, never a DropdownButtonFormField.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('shows loading indicator while fetching', (tester) async {
    final completer = Completer<List<String>>();
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) => completer.future);

    await tester.pumpWidget(buildWidget());
    await tester.pump();

    // Should show a CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Should still have a TextField.
    expect(find.byType(TextField), findsOneWidget);

    completer.complete(['whisper-1']);
    await tester.pumpAndSettle();
  });

  testWidgets('free-text typing works even after successful model fetch',
      (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => ['whisper-1', 'whisper-large-v3-turbo']);

    controller.text = '';
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'my-custom-model');
    expect(controller.text, 'my-custom-model');
  });

  testWidgets('autocomplete suggestions filter by typed text',
      (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => ['whisper-1', 'whisper-large-v3-turbo', 'gpt-4o']);

    controller.text = '';
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Type "whisper" to filter.
    await tester.enterText(find.byType(TextField), 'whisper');
    await tester.pumpAndSettle();

    // Should show whisper models but not gpt-4o.
    expect(find.text('whisper-1'), findsWidgets);
    expect(find.text('whisper-large-v3-turbo'), findsOneWidget);
    expect(find.text('gpt-4o'), findsNothing);
  });

  testWidgets('shows helper text on fetch failure', (tester) async {
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

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    verify(() => mockClient.fetchModels(
          baseUrl: 'https://api.openai.com',
          apiKey: 'test-key',
        )).called(1);

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

  testWidgets('preserves current model text', (tester) async {
    controller.text = 'whisper-1';
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => ['whisper-1', 'whisper-large-v3-turbo']);

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

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
