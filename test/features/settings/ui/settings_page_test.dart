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
import 'package:duckmouth/core/services/sound_service.dart';
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

class MockSoundService extends Mock implements SoundService {}

void main() {
  late MockSettingsCubit mockCubit;
  late MockModelsClient mockModelsClient;
  late MockSoundService mockSoundService;

  const defaultSttConfig = ApiConfig(
    baseUrl: 'https://api.openai.com/v1',
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
    mockSoundService = MockSoundService();

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
        )).thenAnswer((_) async => const FetchModelsSuccess(['whisper-1']));

    // Stub sound service methods
    when(() => mockSoundService.playRecordingStart(volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playRecordingStop(volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playTranscriptionComplete(volume: any(named: 'volume')))
        .thenAnswer((_) async {});

    final sl = GetIt.instance;
    if (!sl.isRegistered<ModelsClient>()) {
      sl.registerLazySingleton<ModelsClient>(() => mockModelsClient);
    }
    if (!sl.isRegistered<SoundService>()) {
      sl.registerLazySingleton<SoundService>(() => mockSoundService);
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

  group('M24: STT preset change updates base URL and model', () {
    testWidgets('Changing STT provider saves preset base URL and model',
        (tester) async {
      await pumpPage(tester);

      // Find the STT provider dropdown (first ProviderPreset dropdown)
      final providerDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<ProviderPreset> &&
            w.initialValue == ProviderPreset.openAi,
      );
      expect(providerDropdown, findsWidgets);
      await tester.tap(providerDropdown.first);
      await tester.pump();

      // Select Groq
      await tester.tap(find.text('Groq').last);
      await tester.pump();

      // Wait for debounce from controller listeners
      await tester.pump(const Duration(milliseconds: 600));

      // Verify saveSettings was called with Groq's base URL and model
      final captured = verify(() => mockCubit.saveSettings(captureAny()))
          .captured;
      expect(captured, isNotEmpty);
      final savedConfig = captured.last as ApiConfig;
      expect(savedConfig.baseUrl, 'https://api.groq.com/openai/v1');
      expect(savedConfig.model, 'whisper-large-v3-turbo');
      expect(savedConfig.providerName, 'groq');
    });
  });

  group('M22: Volume preview sound', () {
    Future<void> dragSliderByLabel(
      WidgetTester tester,
      String label,
    ) async {
      // Find the slider that is a sibling of the label text within a Row.
      final labelFinder = find.text(label);
      await tester.ensureVisible(labelFinder);
      await tester.pump();

      // Find the Slider widget in the same Row as the label.
      final row = find.ancestor(of: labelFinder, matching: find.byType(Row));
      final slider = find.descendant(of: row.first, matching: find.byType(Slider));
      expect(slider, findsOneWidget);

      // Simulate a drag on the slider (move it to roughly 50%).
      final renderBox = tester.renderObject<RenderBox>(slider);
      final center = renderBox.size.center(Offset.zero);

      // Perform a drag gesture — this triggers onChanged and then onChangeEnd.
      await tester.drag(slider, Offset(-center.dx * 0.5, 0));
      await tester.pump();
    }

    testWidgets(
        'Releasing recording start volume slider plays Tink at selected volume',
        (tester) async {
      await pumpPage(tester);
      await dragSliderByLabel(tester, 'Recording start volume');

      verify(() => mockSoundService.playRecordingStart(
            volume: any(named: 'volume'),
          )).called(1);
      verify(() => mockCubit.saveSoundConfig(any())).called(1);
    });

    testWidgets(
        'Releasing recording stop volume slider plays Pop at selected volume',
        (tester) async {
      await pumpPage(tester);
      await dragSliderByLabel(tester, 'Recording stop volume');

      verify(() => mockSoundService.playRecordingStop(
            volume: any(named: 'volume'),
          )).called(1);
      verify(() => mockCubit.saveSoundConfig(any())).called(1);
    });

    testWidgets(
        'Releasing transcription complete volume slider plays Glass at selected volume',
        (tester) async {
      await pumpPage(tester);
      await dragSliderByLabel(tester, 'Transcription complete volume');

      verify(() => mockSoundService.playTranscriptionComplete(
            volume: any(named: 'volume'),
          )).called(1);
      verify(() => mockCubit.saveSoundConfig(any())).called(1);
    });
  });
}
