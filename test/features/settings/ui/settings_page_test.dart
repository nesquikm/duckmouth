import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/api/models_client.dart';
import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/provider_preset.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/settings/ui/settings_page.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockModelsClient extends Mock implements ModelsClient {}

class FakeApiConfig extends Fake implements ApiConfig {}

class FakePostProcessingConfig extends Fake implements PostProcessingConfig {}

class FakeSoundConfig extends Fake implements SoundConfig {}

class FakeAudioFormatConfig extends Fake implements AudioFormatConfig {}

void main() {
  late MockSettingsCubit mockCubit;
  late MockModelsClient mockModelsClient;

  const defaultSttConfig = ApiConfig(
    baseUrl: 'https://api.openai.com',
    apiKey: '',
    model: 'whisper-1',
    providerName: 'openAi',
  );

  const defaultState = SettingsLoaded(
    sttConfig: defaultSttConfig,
    postProcessingConfig: PostProcessingConfig(),
    outputMode: OutputMode.copy,
    hotkeyConfig: HotkeyConfig.defaultConfig,
    soundConfig: SoundConfig(),
    audioFormatConfig: AudioFormatConfig(),
    accessibilityStatus: AccessibilityStatus.unknown,
  );

  setUpAll(() {
    registerFallbackValue(FakeApiConfig());
    registerFallbackValue(FakePostProcessingConfig());
    registerFallbackValue(OutputMode.copy);
    registerFallbackValue(HotkeyConfig.defaultConfig);
    registerFallbackValue(const SoundConfig());
    registerFallbackValue(const AudioFormatConfig());
    registerFallbackValue(ProviderPreset.openAi);
  });

  setUp(() {
    mockCubit = MockSettingsCubit();
    mockModelsClient = MockModelsClient();

    when(() => mockCubit.state).thenReturn(defaultState);
    when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockCubit.saveSettings(any())).thenAnswer((_) async {});
    when(() => mockCubit.savePostProcessingConfig(any()))
        .thenAnswer((_) async {});
    when(() => mockCubit.saveOutputMode(any())).thenAnswer((_) async {});
    when(() => mockCubit.saveHotkeyConfig(any())).thenAnswer((_) async {});
    when(() => mockCubit.saveSoundConfig(any())).thenAnswer((_) async {});
    when(() => mockCubit.saveAudioFormatConfig(any()))
        .thenAnswer((_) async {});
    when(() => mockCubit.saveSelectedInputDevice(any()))
        .thenAnswer((_) async {});
    when(() => mockCubit.selectPreset(any())).thenReturn(null);
    when(() => mockModelsClient.fetchModels(
          baseUrl: any(named: 'baseUrl'),
          apiKey: any(named: 'apiKey'),
        )).thenAnswer((_) async => <String>[]);

    final sl = GetIt.instance;
    if (!sl.isRegistered<ModelsClient>()) {
      sl.registerLazySingleton<ModelsClient>(() => mockModelsClient);
    }
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget buildPage() {
    return MaterialApp(
      home: BlocProvider<SettingsCubit>.value(
        value: mockCubit,
        child: const SettingsPage(),
      ),
    );
  }

  /// Pump the widget and let async microtasks run without waiting for
  /// all timers to complete (avoids pumpAndSettle timeout from debounce
  /// timers and native AudioRecorder calls in tests).
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(buildPage());
    // Give enough frames for async initState calls to complete.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('M21: Auto-save settings', () {
    testWidgets('Save button is absent from the UI', (tester) async {
      await pumpPage(tester);

      expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
    });

    testWidgets('Changing output mode dropdown triggers immediate save',
        (tester) async {
      await pumpPage(tester);

      // Find and tap the output mode dropdown — scroll it into view first
      final outputDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<OutputMode> &&
            w.initialValue == OutputMode.copy,
      );
      await tester.ensureVisible(outputDropdown);
      await tester.pump();
      await tester.tap(outputDropdown);
      await tester.pump();

      // Select 'paste' option
      await tester.tap(find.text(OutputMode.paste.label).last);
      await tester.pump();

      verify(() => mockCubit.saveOutputMode(OutputMode.paste)).called(1);
    });

    testWidgets('Toggling sound feedback switch triggers immediate save',
        (tester) async {
      await pumpPage(tester);

      final soundSwitch = find.byWidgetPredicate(
        (w) =>
            w is SwitchListTile &&
            w.title is Text &&
            (w.title as Text).data == 'Enable sound feedback',
      );
      await tester.ensureVisible(soundSwitch);
      await tester.pump();
      await tester.tap(soundSwitch);
      await tester.pump();

      verify(() => mockCubit.saveSoundConfig(any())).called(1);
    });

    testWidgets('Toggling post-processing switch triggers immediate save',
        (tester) async {
      await pumpPage(tester);

      final ppSwitch = find.byWidgetPredicate(
        (w) =>
            w is SwitchListTile &&
            w.title is Text &&
            (w.title as Text).data == 'Enable post-processing',
      );
      await tester.ensureVisible(ppSwitch);
      await tester.pump();
      await tester.tap(ppSwitch);
      await tester.pump();

      verify(() => mockCubit.savePostProcessingConfig(any())).called(1);
    });

    testWidgets('Text field changes trigger debounced save', (tester) async {
      await pumpPage(tester);

      // Find the API Key text field (the STT one, not the PP one)
      final apiKeyField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'API Key' &&
            w.obscureText == true,
      );
      expect(apiKeyField, findsWidgets);

      // Use the first match (STT API Key)
      await tester.enterText(apiKeyField.first, 'new-key');
      await tester.pump();

      // Should NOT have saved yet (debounce pending)
      verifyNever(() => mockCubit.saveSettings(any()));

      // Wait for debounce duration to expire
      await tester.pump(const Duration(milliseconds: 500));

      // Now the debounced save should have fired
      verify(() => mockCubit.saveSettings(any())).called(1);
    });

    testWidgets('Multiple rapid text changes only trigger one save',
        (tester) async {
      await pumpPage(tester);

      final apiKeyField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'API Key' &&
            w.obscureText == true,
      );

      // Type multiple characters rapidly
      await tester.enterText(apiKeyField.first, 'k');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(apiKeyField.first, 'ke');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(apiKeyField.first, 'key');
      await tester.pump(const Duration(milliseconds: 100));

      // Still within debounce window — nothing saved yet
      verifyNever(() => mockCubit.saveSettings(any()));

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 500));

      // Should have saved exactly once with final value
      verify(() => mockCubit.saveSettings(any())).called(1);
    });
  });
}
