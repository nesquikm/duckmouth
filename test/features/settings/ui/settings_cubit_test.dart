import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/provider_preset.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockAccessibilityService extends Mock implements AccessibilityService {}

class FakeApiConfig extends Fake implements ApiConfig {}

class FakePostProcessingConfig extends Fake implements PostProcessingConfig {}

class FakeHotkeyConfig extends Fake implements HotkeyConfig {}

void main() {
  late MockSettingsRepository mockRepo;
  late MockAccessibilityService mockAccessibility;

  setUpAll(() {
    registerFallbackValue(FakeApiConfig());
    registerFallbackValue(FakePostProcessingConfig());
    registerFallbackValue(OutputMode.copy);
    registerFallbackValue(HotkeyConfig.defaultConfig);
    registerFallbackValue(const SoundConfig());
    registerFallbackValue(const AudioFormatConfig());
  });

  setUp(() {
    mockRepo = MockSettingsRepository();
    mockAccessibility = MockAccessibilityService();
    when(() => mockAccessibility.checkPermission())
        .thenAnswer((_) async => AccessibilityStatus.unknown);
  });

  const defaultConfig = ApiConfig(
    baseUrl: 'https://api.openai.com',
    apiKey: '',
    model: 'whisper-1',
    providerName: 'openAi',
  );

  const savedConfig = ApiConfig(
    baseUrl: 'https://api.groq.com/openai',
    apiKey: 'test-key',
    model: 'whisper-large-v3-turbo',
    providerName: 'groq',
  );

  const defaultPpConfig = PostProcessingConfig();
  const defaultHotkeyConfig = HotkeyConfig.defaultConfig;

  group('SettingsCubit', () {
    test('initial state is SettingsLoading', () {
      final cubit = SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      expect(cubit.state, isA<SettingsLoading>());
      cubit.close();
    });

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits SettingsLoaded with default when no saved config',
      build: () {
        when(() => mockRepo.loadSttConfig()).thenAnswer((_) async => null);
        when(() => mockRepo.loadPostProcessingConfig())
            .thenAnswer((_) async => defaultPpConfig);
        when(() => mockRepo.loadOutputMode())
            .thenAnswer((_) async => OutputMode.copy);
        when(() => mockRepo.loadHotkeyConfig())
            .thenAnswer((_) async => defaultHotkeyConfig);
        when(() => mockRepo.loadSoundConfig())
            .thenAnswer((_) async => const SoundConfig());
        when(() => mockRepo.loadAudioFormatConfig())
            .thenAnswer((_) async => const AudioFormatConfig());
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits SettingsLoaded with saved config',
      build: () {
        when(() => mockRepo.loadSttConfig())
            .thenAnswer((_) async => savedConfig);
        when(() => mockRepo.loadPostProcessingConfig())
            .thenAnswer((_) async => defaultPpConfig);
        when(() => mockRepo.loadOutputMode())
            .thenAnswer((_) async => OutputMode.copy);
        when(() => mockRepo.loadHotkeyConfig())
            .thenAnswer((_) async => defaultHotkeyConfig);
        when(() => mockRepo.loadSoundConfig())
            .thenAnswer((_) async => const SoundConfig());
        when(() => mockRepo.loadAudioFormatConfig())
            .thenAnswer((_) async => const AudioFormatConfig());
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsLoaded(
          sttConfig: savedConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits SettingsError on exception',
      build: () {
        when(() => mockRepo.loadSttConfig())
            .thenThrow(Exception('storage failure'));
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsError(message: 'Exception: storage failure'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveSettings persists config and emits SettingsLoaded',
      build: () {
        when(() => mockRepo.saveSttConfig(savedConfig))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: defaultConfig),
      act: (cubit) => cubit.saveSettings(savedConfig),
      expect: () => [
        const SettingsLoaded(
          sttConfig: savedConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.saveSttConfig(savedConfig)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveSettings emits SettingsError on exception',
      build: () {
        when(() => mockRepo.saveSttConfig(any()))
            .thenThrow(Exception('write error'));
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.saveSettings(savedConfig),
      expect: () => [
        const SettingsError(message: 'Exception: write error'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'selectPreset emits SettingsLoaded with preset config and current key',
      build: () {
        when(() => mockRepo.loadSttConfig())
            .thenAnswer((_) async => savedConfig);
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: savedConfig),
      act: (cubit) => cubit.selectPreset(ProviderPreset.openAi),
      expect: () => [
        SettingsLoaded(
          sttConfig: ApiConfig(
            baseUrl: 'https://api.openai.com',
            apiKey: savedConfig.apiKey,
            model: 'whisper-1',
            providerName: 'openAi',
          ),
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'selectPreset uses empty key when state is not SettingsLoaded',
      build: () => SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility),
      act: (cubit) => cubit.selectPreset(ProviderPreset.groq),
      expect: () => [
        const SettingsLoaded(
          sttConfig: ApiConfig(
            baseUrl: 'https://api.groq.com/openai',
            apiKey: '',
            model: 'whisper-large-v3-turbo',
            providerName: 'groq',
          ),
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'savePostProcessingConfig persists and emits updated state',
      build: () {
        when(() => mockRepo.savePostProcessingConfig(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: defaultConfig),
      act: (cubit) => cubit.savePostProcessingConfig(
        const PostProcessingConfig(enabled: true, prompt: 'Custom'),
      ),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: PostProcessingConfig(
            enabled: true,
            prompt: 'Custom',
          ),
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.savePostProcessingConfig(any())).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'savePostProcessingConfig emits SettingsError on exception',
      build: () {
        when(() => mockRepo.savePostProcessingConfig(any()))
            .thenThrow(Exception('write error'));
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.savePostProcessingConfig(defaultPpConfig),
      expect: () => [
        const SettingsError(message: 'Exception: write error'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits SettingsLoaded with saved output mode',
      build: () {
        when(() => mockRepo.loadSttConfig()).thenAnswer((_) async => null);
        when(() => mockRepo.loadPostProcessingConfig())
            .thenAnswer((_) async => defaultPpConfig);
        when(() => mockRepo.loadOutputMode())
            .thenAnswer((_) async => OutputMode.paste);
        when(() => mockRepo.loadHotkeyConfig())
            .thenAnswer((_) async => defaultHotkeyConfig);
        when(() => mockRepo.loadSoundConfig())
            .thenAnswer((_) async => const SoundConfig());
        when(() => mockRepo.loadAudioFormatConfig())
            .thenAnswer((_) async => const AudioFormatConfig());
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          outputMode: OutputMode.paste,
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveOutputMode persists and emits updated state',
      build: () {
        when(() => mockRepo.saveOutputMode(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: defaultConfig),
      act: (cubit) => cubit.saveOutputMode(OutputMode.both),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          outputMode: OutputMode.both,
          hotkeyConfig: defaultHotkeyConfig,
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.saveOutputMode(OutputMode.both)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveOutputMode emits SettingsError on exception',
      build: () {
        when(() => mockRepo.saveOutputMode(any()))
            .thenThrow(Exception('write error'));
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.saveOutputMode(OutputMode.paste),
      expect: () => [
        const SettingsError(message: 'Exception: write error'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveHotkeyConfig persists and emits updated state',
      build: () {
        when(() => mockRepo.saveHotkeyConfig(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: defaultConfig),
      act: (cubit) => cubit.saveHotkeyConfig(
        const HotkeyConfig(
          keyCode: 0x00070004,
          modifiers: ['alt'],
          mode: HotkeyMode.pushToTalk,
        ),
      ),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: HotkeyConfig(
            keyCode: 0x00070004,
            modifiers: ['alt'],
            mode: HotkeyMode.pushToTalk,
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.saveHotkeyConfig(any())).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveHotkeyConfig emits SettingsError on exception',
      build: () {
        when(() => mockRepo.saveHotkeyConfig(any()))
            .thenThrow(Exception('write error'));
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.saveHotkeyConfig(defaultHotkeyConfig),
      expect: () => [
        const SettingsError(message: 'Exception: write error'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveSoundConfig persists and emits updated state',
      build: () {
        when(() => mockRepo.saveSoundConfig(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: defaultConfig),
      act: (cubit) => cubit.saveSoundConfig(
        const SoundConfig(enabled: false, startVolume: 0.5),
      ),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
          soundConfig: SoundConfig(enabled: false, startVolume: 0.5),
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.saveSoundConfig(any())).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveSoundConfig emits SettingsError on exception',
      build: () {
        when(() => mockRepo.saveSoundConfig(any()))
            .thenThrow(Exception('write error'));
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.saveSoundConfig(const SoundConfig()),
      expect: () => [
        const SettingsError(message: 'Exception: write error'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings loads audioFormatConfig',
      build: () {
        when(() => mockRepo.loadSttConfig()).thenAnswer((_) async => null);
        when(() => mockRepo.loadPostProcessingConfig())
            .thenAnswer((_) async => defaultPpConfig);
        when(() => mockRepo.loadOutputMode())
            .thenAnswer((_) async => OutputMode.copy);
        when(() => mockRepo.loadHotkeyConfig())
            .thenAnswer((_) async => defaultHotkeyConfig);
        when(() => mockRepo.loadSoundConfig())
            .thenAnswer((_) async => const SoundConfig());
        when(() => mockRepo.loadAudioFormatConfig()).thenAnswer(
          (_) async => const AudioFormatConfig(
            preset: QualityPreset.balanced,
          ),
        );
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
          audioFormatConfig: AudioFormatConfig(
            preset: QualityPreset.balanced,
          ),
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveAudioFormatConfig persists and emits updated state',
      build: () {
        when(() => mockRepo.saveAudioFormatConfig(any()))
            .thenAnswer((_) async {});
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: defaultConfig),
      act: (cubit) => cubit.saveAudioFormatConfig(
        const AudioFormatConfig(preset: QualityPreset.smallest),
      ),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
          audioFormatConfig: AudioFormatConfig(
            preset: QualityPreset.smallest,
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockRepo.saveAudioFormatConfig(any())).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'saveAudioFormatConfig emits SettingsError on exception',
      build: () {
        when(() => mockRepo.saveAudioFormatConfig(any()))
            .thenThrow(Exception('write error'));
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.saveAudioFormatConfig(const AudioFormatConfig()),
      expect: () => [
        const SettingsError(message: 'Exception: write error'),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings includes accessibility permission status',
      build: () {
        when(() => mockRepo.loadSttConfig()).thenAnswer((_) async => null);
        when(() => mockRepo.loadPostProcessingConfig())
            .thenAnswer((_) async => defaultPpConfig);
        when(() => mockRepo.loadOutputMode())
            .thenAnswer((_) async => OutputMode.copy);
        when(() => mockRepo.loadHotkeyConfig())
            .thenAnswer((_) async => defaultHotkeyConfig);
        when(() => mockRepo.loadSoundConfig())
            .thenAnswer((_) async => const SoundConfig());
        when(() => mockRepo.loadAudioFormatConfig())
            .thenAnswer((_) async => const AudioFormatConfig());
        when(() => mockAccessibility.checkPermission())
            .thenAnswer((_) async => AccessibilityStatus.granted);
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
          accessibilityStatus: AccessibilityStatus.granted,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'checkAccessibilityPermission updates state',
      build: () {
        when(() => mockAccessibility.checkPermission())
            .thenAnswer((_) async => AccessibilityStatus.denied);
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(sttConfig: defaultConfig),
      act: (cubit) => cubit.checkAccessibilityPermission(),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
          accessibilityStatus: AccessibilityStatus.denied,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'requestAccessibilityPermission calls service and re-checks',
      build: () {
        when(() => mockAccessibility.requestPermission())
            .thenAnswer((_) async {});
        when(() => mockAccessibility.checkPermission())
            .thenAnswer((_) async => AccessibilityStatus.granted);
        return SettingsCubit(repository: mockRepo, accessibilityService: mockAccessibility);
      },
      seed: () => const SettingsLoaded(
        sttConfig: defaultConfig,
        accessibilityStatus: AccessibilityStatus.denied,
      ),
      act: (cubit) => cubit.requestAccessibilityPermission(),
      expect: () => [
        const SettingsLoaded(
          sttConfig: defaultConfig,
          postProcessingConfig: defaultPpConfig,
          hotkeyConfig: defaultHotkeyConfig,
          accessibilityStatus: AccessibilityStatus.granted,
        ),
      ],
      verify: (_) {
        verify(() => mockAccessibility.requestPermission()).called(1);
        verify(() => mockAccessibility.checkPermission()).called(1);
      },
    );
  });
}
