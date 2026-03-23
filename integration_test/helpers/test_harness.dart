import 'package:get_it/get_it.dart';

import 'package:duckmouth/core/api/llm_client.dart';
import 'package:duckmouth/core/api/models_client.dart';
import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/core/services/sound_service.dart';
import 'package:duckmouth/features/history/domain/history_repository.dart';
import 'package:duckmouth/features/history/ui/history_cubit.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_service.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_cubit.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

import 'fakes/fake_accessibility_service.dart';
import 'fakes/fake_clipboard_service.dart';
import 'fakes/fake_history_repository.dart';
import 'fakes/fake_hotkey_service.dart';
import 'fakes/fake_llm_client.dart';
import 'fakes/fake_models_client.dart';
import 'fakes/fake_openai_client.dart';
import 'fakes/fake_post_processing_repository.dart';
import 'fakes/fake_recording_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_sound_service.dart';
import 'fakes/fake_stt_repository.dart';

/// Test harness that configures GetIt with fake services for integration tests.
///
/// NOTE: The SettingsCubit listener in HomePage calls `updateOpenAiClient()`
/// and `updateLlmClient()` when settings load, which re-registers
/// `SttRepository` and `PostProcessingRepository` using the registered
/// `OpenAiClient`/`LlmClient`. To handle this gracefully, we register
/// fake clients and let the real repos wrap them. The `TranscriptionCubit`
/// and `PostProcessingCubit` use `repositoryFactory` which calls
/// `sl<SttRepository>()` — so after re-registration, they get the real
/// repos with fake clients, which still produce valid responses.
class TestHarness {
  TestHarness({
    FakeRecordingRepository? recordingRepository,
    FakeSttRepository? sttRepository,
    FakePostProcessingRepository? postProcessingRepository,
    FakeSoundService? soundService,
    FakeAccessibilityService? accessibilityService,
    FakeClipboardService? clipboardService,
    FakeHotkeyService? hotkeyService,
    FakeSettingsRepository? settingsRepository,
    FakeHistoryRepository? historyRepository,
    PostProcessingConfig? postProcessingConfig,
  })  : recordingRepository =
            recordingRepository ?? FakeRecordingRepository(),
        sttRepository = sttRepository ?? FakeSttRepository(),
        postProcessingRepository =
            postProcessingRepository ?? FakePostProcessingRepository(),
        soundService = soundService ?? FakeSoundService(),
        accessibilityService =
            accessibilityService ?? FakeAccessibilityService(),
        clipboardService = clipboardService ?? FakeClipboardService(),
        hotkeyService = hotkeyService ?? FakeHotkeyService(),
        settingsRepository = settingsRepository ??
            FakeSettingsRepository(
              initialPpConfig:
                  postProcessingConfig ?? const PostProcessingConfig(),
            ),
        historyRepository =
            historyRepository ?? FakeHistoryRepository(),
        _postProcessingConfig =
            postProcessingConfig ?? const PostProcessingConfig();

  final FakeRecordingRepository recordingRepository;
  final FakeSttRepository sttRepository;
  final FakePostProcessingRepository postProcessingRepository;
  final FakeSoundService soundService;
  final FakeAccessibilityService accessibilityService;
  final FakeClipboardService clipboardService;
  final FakeHotkeyService hotkeyService;
  final FakeSettingsRepository settingsRepository;
  final FakeHistoryRepository historyRepository;
  final PostProcessingConfig _postProcessingConfig;

  final _sl = GetIt.instance;

  /// Register all fakes in GetIt. Call this before pumpWidget.
  void setUp() {
    _sl.allowReassignment = true;

    // Core services
    _sl.registerLazySingleton<AccessibilityService>(() => accessibilityService);
    _sl.registerLazySingleton<ClipboardService>(() => clipboardService);
    _sl.registerLazySingleton<SoundService>(() => soundService);

    // Settings
    _sl.registerLazySingleton<SettingsRepository>(() => settingsRepository);
    _sl.registerFactory<SettingsCubit>(
      () => SettingsCubit(
        repository: _sl<SettingsRepository>(),
        accessibilityService: _sl<AccessibilityService>(),
      ),
    );

    // Recording
    _sl.registerLazySingleton<RecordingRepository>(() => recordingRepository);
    _sl.registerFactory<RecordingCubit>(
      () => RecordingCubit(repository: _sl<RecordingRepository>()),
    );

    // OpenAI/LLM clients — register proper fakes so updateOpenAiClient()
    // and updateLlmClient() don't crash when re-registering repos.
    _sl.registerFactory<OpenAiClient>(() => FakeOpenAiClient());
    _sl.registerFactory<LlmClient>(() => FakeLlmClient());
    _sl.registerFactory<ModelsClient>(() => FakeModelsClient());

    // STT — register our fake repo. Note: updateOpenAiClient() will
    // re-register SttRepository with SttRepositoryImpl(FakeOpenAiClient()),
    // but TranscriptionCubit uses repositoryFactory to resolve it.
    _sl.registerFactory<SttRepository>(() => sttRepository);
    _sl.registerFactory<TranscriptionCubit>(
      () => TranscriptionCubit(repositoryFactory: () => sttRepository),
    );

    // Post-processing — same as STT, hardcode the fake in the cubit.
    _sl.registerFactory<PostProcessingRepository>(
      () => postProcessingRepository,
    );
    _sl.registerFactory<PostProcessingCubit>(
      () => PostProcessingCubit(
        repositoryFactory: () => postProcessingRepository,
        config: _postProcessingConfig,
      ),
    );

    // Hotkey
    _sl.registerLazySingleton<HotkeyService>(() => hotkeyService);
    _sl.registerFactory<HotkeyCubit>(
      () => HotkeyCubit(service: _sl<HotkeyService>()),
    );

    // History
    _sl.registerLazySingleton<HistoryRepository>(() => historyRepository);
    _sl.registerFactory<HistoryCubit>(
      () => HistoryCubit(repository: _sl<HistoryRepository>()),
    );
  }

  /// Reset GetIt after each test.
  Future<void> tearDown() async {
    await _sl.reset();
  }
}
