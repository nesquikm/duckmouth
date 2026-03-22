import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
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
  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(const SettingsLoading());

  final SettingsRepository _repository;

  /// Load settings from the repository.
  Future<void> loadSettings() async {
    try {
      final config = await _repository.loadSttConfig();
      final ppConfig = await _repository.loadPostProcessingConfig();
      final outputMode = await _repository.loadOutputMode();
      emit(SettingsLoaded(
        sttConfig: config ?? _kDefaultConfig,
        postProcessingConfig: ppConfig,
        outputMode: outputMode,
      ));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given STT [config] and emit the updated state.
  Future<void> saveSettings(ApiConfig config) async {
    try {
      await _repository.saveSttConfig(config);
      final currentState = state;
      final ppConfig = currentState is SettingsLoaded
          ? currentState.postProcessingConfig
          : const PostProcessingConfig();
      final outputMode = currentState is SettingsLoaded
          ? currentState.outputMode
          : OutputMode.copy;
      emit(SettingsLoaded(
        sttConfig: config,
        postProcessingConfig: ppConfig,
        outputMode: outputMode,
      ));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given post-processing [config] and emit the updated state.
  Future<void> savePostProcessingConfig(PostProcessingConfig config) async {
    try {
      await _repository.savePostProcessingConfig(config);
      final currentState = state;
      final sttConfig = currentState is SettingsLoaded
          ? currentState.sttConfig
          : _kDefaultConfig;
      final outputMode = currentState is SettingsLoaded
          ? currentState.outputMode
          : OutputMode.copy;
      emit(SettingsLoaded(
        sttConfig: sttConfig,
        postProcessingConfig: config,
        outputMode: outputMode,
      ));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given [outputMode] and emit the updated state.
  Future<void> saveOutputMode(OutputMode outputMode) async {
    try {
      await _repository.saveOutputMode(outputMode);
      final currentState = state;
      final sttConfig = currentState is SettingsLoaded
          ? currentState.sttConfig
          : _kDefaultConfig;
      final ppConfig = currentState is SettingsLoaded
          ? currentState.postProcessingConfig
          : const PostProcessingConfig();
      emit(SettingsLoaded(
        sttConfig: sttConfig,
        postProcessingConfig: ppConfig,
        outputMode: outputMode,
      ));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Apply a provider preset, keeping the current API key.
  void selectPreset(ProviderPreset preset) {
    final currentState = state;
    final currentKey =
        currentState is SettingsLoaded ? currentState.sttConfig.apiKey : '';
    final ppConfig = currentState is SettingsLoaded
        ? currentState.postProcessingConfig
        : const PostProcessingConfig();
    final outputMode = currentState is SettingsLoaded
        ? currentState.outputMode
        : OutputMode.copy;

    final config = preset.toApiConfig(apiKey: currentKey);
    emit(SettingsLoaded(
      sttConfig: config,
      postProcessingConfig: ppConfig,
      outputMode: outputMode,
    ));
  }
}
