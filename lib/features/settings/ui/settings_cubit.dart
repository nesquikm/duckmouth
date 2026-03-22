import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/provider_preset.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';

/// Default configuration used when no settings have been saved.
const _kDefaultConfig = ApiConfig(
  baseUrl: 'https://api.openai.com',
  apiKey: '',
  model: 'whisper-1',
  providerName: 'openAi',
);

/// Cubit managing the settings feature state.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required SettingsRepository repository,
    required AccessibilityService accessibilityService,
  })  : _repository = repository,
        _accessibilityService = accessibilityService,
        super(const SettingsLoading());

  final SettingsRepository _repository;
  final AccessibilityService _accessibilityService;

  /// Extracts current loaded values or defaults from state.
  SettingsLoaded _currentOrDefault({
    ApiConfig? sttConfig,
    PostProcessingConfig? postProcessingConfig,
    OutputMode? outputMode,
    HotkeyConfig? hotkeyConfig,
    SoundConfig? soundConfig,
    AudioFormatConfig? audioFormatConfig,
    AccessibilityStatus? accessibilityStatus,
    String? Function()? selectedInputDeviceId,
  }) {
    final currentState = state;
    return SettingsLoaded(
      sttConfig: sttConfig ??
          (currentState is SettingsLoaded
              ? currentState.sttConfig
              : _kDefaultConfig),
      postProcessingConfig: postProcessingConfig ??
          (currentState is SettingsLoaded
              ? currentState.postProcessingConfig
              : const PostProcessingConfig()),
      outputMode: outputMode ??
          (currentState is SettingsLoaded
              ? currentState.outputMode
              : OutputMode.copy),
      hotkeyConfig: hotkeyConfig ??
          (currentState is SettingsLoaded
              ? currentState.hotkeyConfig
              : HotkeyConfig.defaultConfig),
      soundConfig: soundConfig ??
          (currentState is SettingsLoaded
              ? currentState.soundConfig
              : const SoundConfig()),
      audioFormatConfig: audioFormatConfig ??
          (currentState is SettingsLoaded
              ? currentState.audioFormatConfig
              : const AudioFormatConfig()),
      accessibilityStatus: accessibilityStatus ??
          (currentState is SettingsLoaded
              ? currentState.accessibilityStatus
              : AccessibilityStatus.unknown),
      selectedInputDeviceId: selectedInputDeviceId != null
          ? selectedInputDeviceId()
          : (currentState is SettingsLoaded
              ? currentState.selectedInputDeviceId
              : null),
    );
  }

  /// Load settings from the repository.
  Future<void> loadSettings() async {
    try {
      final config = await _repository.loadSttConfig();
      final ppConfig = await _repository.loadPostProcessingConfig();
      final outputMode = await _repository.loadOutputMode();
      final hotkeyConfig = await _repository.loadHotkeyConfig();
      final soundConfig = await _repository.loadSoundConfig();
      final audioFormatConfig = await _repository.loadAudioFormatConfig();
      final selectedDevice = await _repository.loadSelectedInputDevice();
      final axStatus = await _accessibilityService.checkPermission();
      emit(SettingsLoaded(
        sttConfig: config ?? _kDefaultConfig,
        postProcessingConfig: ppConfig,
        outputMode: outputMode,
        hotkeyConfig: hotkeyConfig,
        soundConfig: soundConfig,
        audioFormatConfig: audioFormatConfig,
        accessibilityStatus: axStatus,
        selectedInputDeviceId: selectedDevice,
      ));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Check the current Accessibility permission status and update state.
  Future<void> checkAccessibilityPermission() async {
    final status = await _accessibilityService.checkPermission();
    emit(_currentOrDefault(accessibilityStatus: status));
  }

  /// Prompt the user to grant Accessibility permission, then re-check.
  Future<void> requestAccessibilityPermission() async {
    await _accessibilityService.requestPermission();
    // Re-check after prompt (user may not have granted yet).
    await checkAccessibilityPermission();
  }

  /// Save the given STT [config] and emit the updated state.
  Future<void> saveSettings(ApiConfig config) async {
    try {
      await _repository.saveSttConfig(config);
      emit(_currentOrDefault(sttConfig: config));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given post-processing [config] and emit the updated state.
  Future<void> savePostProcessingConfig(PostProcessingConfig config) async {
    try {
      await _repository.savePostProcessingConfig(config);
      emit(_currentOrDefault(postProcessingConfig: config));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given [outputMode] and emit the updated state.
  Future<void> saveOutputMode(OutputMode outputMode) async {
    try {
      await _repository.saveOutputMode(outputMode);
      emit(_currentOrDefault(outputMode: outputMode));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given [hotkeyConfig] and emit the updated state.
  Future<void> saveHotkeyConfig(HotkeyConfig hotkeyConfig) async {
    try {
      await _repository.saveHotkeyConfig(hotkeyConfig);
      emit(_currentOrDefault(hotkeyConfig: hotkeyConfig));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given [soundConfig] and emit the updated state.
  Future<void> saveSoundConfig(SoundConfig soundConfig) async {
    try {
      await _repository.saveSoundConfig(soundConfig);
      emit(_currentOrDefault(soundConfig: soundConfig));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given [audioFormatConfig] and emit the updated state.
  Future<void> saveAudioFormatConfig(AudioFormatConfig audioFormatConfig) async {
    try {
      await _repository.saveAudioFormatConfig(audioFormatConfig);
      emit(_currentOrDefault(audioFormatConfig: audioFormatConfig));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the selected input device ID and emit the updated state.
  Future<void> saveSelectedInputDevice(String? deviceId) async {
    try {
      await _repository.saveSelectedInputDevice(deviceId);
      emit(_currentOrDefault(selectedInputDeviceId: () => deviceId));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Apply a provider preset, keeping the current API key.
  void selectPreset(ProviderPreset preset) {
    final currentState = state;
    final currentKey =
        currentState is SettingsLoaded ? currentState.sttConfig.apiKey : '';

    final config = preset.toApiConfig(apiKey: currentKey);
    emit(_currentOrDefault(sttConfig: config));
  }
}
