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
    String baseUrl = 'https://api.openai.com/v1',
    String apiKey = 'test-key',
    ModelType modelType = ModelType.stt,
    bool enabled = true,
    String? hintText,
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
          hintText: hintText,
        ),
      ),
    );
  }

  testWidgets('always shows TextField (not locked dropdown)', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async =>
          const FetchModelsSuccess(['whisper-1', 'whisper-large-v3-turbo']),
    );

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Should always show a TextField, never a DropdownButtonFormField.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('shows loading indicator while fetching', (tester) async {
    final completer = Completer<FetchModelsResult>();
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

    completer.complete(const FetchModelsSuccess(['whisper-1']));
    await tester.pumpAndSettle();
  });

  testWidgets('free-text typing works even after successful model fetch',
      (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async =>
          const FetchModelsSuccess(['whisper-1', 'whisper-large-v3-turbo']),
    );

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
        )).thenAnswer(
      (_) async => const FetchModelsSuccess(
          ['gpt-4o', 'whisper-1', 'whisper-large-v3-turbo']),
    );

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

  testWidgets('shows specific failure reason in helper text', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async =>
          const FetchModelsFailure('Unauthorized \u2014 check API key'),
    );

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('Unauthorized \u2014 check API key'),
      findsOneWidget,
    );
  });

  testWidgets('shows generic failure reason on empty result', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async =>
          const FetchModelsFailure('Network error \u2014 check connection'),
    );

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('Network error \u2014 check connection'),
      findsOneWidget,
    );
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
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'test-key',
        )).thenAnswer(
      (_) async => const FetchModelsSuccess(['whisper-1']),
    );

    when(() => mockClient.fetchModels(
          baseUrl: 'https://api.groq.com/openai/v1',
          apiKey: 'test-key',
        )).thenAnswer(
      (_) async => const FetchModelsSuccess(['whisper-large-v3-turbo']),
    );

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    verify(() => mockClient.fetchModels(
          baseUrl: 'https://api.openai.com/v1',
          apiKey: 'test-key',
        )).called(1);

    await tester
        .pumpWidget(buildWidget(baseUrl: 'https://api.groq.com/openai/v1'));
    await tester.pumpAndSettle();

    verify(() => mockClient.fetchModels(
          baseUrl: 'https://api.groq.com/openai/v1',
          apiKey: 'test-key',
        )).called(1);
  });

  testWidgets('refreshes when apiKey changes', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: 'key-1',
        )).thenAnswer(
      (_) async => const FetchModelsSuccess(['whisper-1']),
    );

    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: 'key-2',
        )).thenAnswer(
      (_) async =>
          const FetchModelsSuccess(['whisper-1', 'whisper-large-v3-turbo']),
    );

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
        )).thenAnswer(
      (_) async =>
          const FetchModelsSuccess(['whisper-1', 'whisper-large-v3-turbo']),
    );

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('whisper-1'), findsOneWidget);
  });

  testWidgets('free-text fallback allows typing on failure', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async =>
          const FetchModelsFailure('Not found \u2014 check endpoint URL'),
    );

    controller.text = '';
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'my-custom-model');
    expect(controller.text, 'my-custom-model');
  });

  testWidgets('model field stays editable on error', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async =>
          const FetchModelsFailure('Unauthorized \u2014 check API key'),
    );

    controller.text = 'gpt-4o';
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    // Should still be editable
    await tester.enterText(textField, 'new-model');
    expect(controller.text, 'new-model');
  });

  testWidgets('shows hintText when provided and no failure', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async => const FetchModelsSuccess(['grok-4-1-fast-non-reasoning']),
    );

    await tester.pumpWidget(
      buildWidget(hintText: 'This provider has no STT models'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This provider has no STT models'),
      findsOneWidget,
    );
  });

  testWidgets('failure reason overrides hintText', (tester) async {
    when(() => mockClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer(
      (_) async =>
          const FetchModelsFailure('Unauthorized \u2014 check API key'),
    );

    await tester.pumpWidget(
      buildWidget(hintText: 'This provider has no STT models'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unauthorized \u2014 check API key'),
      findsOneWidget,
    );
    expect(
      find.text('This provider has no STT models'),
      findsNothing,
    );
  });
}
