import 'package:flutter_bloc/flutter_bloc.dart';

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
      emit(SettingsLoaded(sttConfig: config ?? _kDefaultConfig));
    } on Exception catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Save the given [config] and emit the updated state.
  Future<void> saveSettings(ApiConfig config) async {
    try {
      await _repository.saveSttConfig(config);
      emit(SettingsLoaded(sttConfig: config));
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
    emit(SettingsLoaded(sttConfig: config));
  }
}
