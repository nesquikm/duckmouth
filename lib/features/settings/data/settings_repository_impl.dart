import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';

/// Keys used in SharedPreferences.
const _kBaseUrl = 'stt_base_url';
const _kModel = 'stt_model';
const _kProviderName = 'stt_provider_name';

/// Key used in FlutterSecureStorage.
const _kApiKey = 'stt_api_key';

/// Post-processing keys in SharedPreferences.
const _kPpEnabled = 'pp_enabled';
const _kPpPrompt = 'pp_prompt';
const _kPpBaseUrl = 'pp_base_url';
const _kPpModel = 'pp_model';
const _kPpProviderName = 'pp_provider_name';

/// Post-processing key in FlutterSecureStorage.
const _kPpApiKey = 'pp_api_key';

/// Output mode key in SharedPreferences.
const _kOutputMode = 'output_mode';

/// [SettingsRepository] backed by SharedPreferences (non-sensitive values)
/// and FlutterSecureStorage (API keys).
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  })  : _prefs = prefs,
        _secureStorage = secureStorage;

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<ApiConfig?> loadSttConfig() async {
    final baseUrl = _prefs.getString(_kBaseUrl);
    final model = _prefs.getString(_kModel);
    final providerName = _prefs.getString(_kProviderName);

    // If no provider has been saved yet, return null.
    if (providerName == null) return null;

    final apiKey = await _secureStorage.read(key: _kApiKey) ?? '';

    return ApiConfig(
      baseUrl: baseUrl ?? '',
      apiKey: apiKey,
      model: model ?? '',
      providerName: providerName,
    );
  }

  @override
  Future<void> saveSttConfig(ApiConfig config) async {
    await Future.wait([
      _prefs.setString(_kBaseUrl, config.baseUrl),
      _prefs.setString(_kModel, config.model),
      _prefs.setString(_kProviderName, config.providerName),
      _secureStorage.write(key: _kApiKey, value: config.apiKey),
    ]);
  }

  @override
  Future<PostProcessingConfig> loadPostProcessingConfig() async {
    final enabled = _prefs.getBool(_kPpEnabled) ?? false;
    final prompt = _prefs.getString(_kPpPrompt) ?? kDefaultPostProcessingPrompt;
    final baseUrl = _prefs.getString(_kPpBaseUrl) ?? 'https://api.openai.com';
    final model = _prefs.getString(_kPpModel) ?? 'gpt-4o-mini';
    final providerName = _prefs.getString(_kPpProviderName) ?? 'openAi';
    final apiKey = await _secureStorage.read(key: _kPpApiKey) ?? '';

    return PostProcessingConfig(
      enabled: enabled,
      prompt: prompt,
      llmConfig: ApiConfig(
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
        providerName: providerName,
      ),
    );
  }

  @override
  Future<void> savePostProcessingConfig(PostProcessingConfig config) async {
    await Future.wait([
      _prefs.setBool(_kPpEnabled, config.enabled),
      _prefs.setString(_kPpPrompt, config.prompt),
      _prefs.setString(_kPpBaseUrl, config.llmConfig.baseUrl),
      _prefs.setString(_kPpModel, config.llmConfig.model),
      _prefs.setString(_kPpProviderName, config.llmConfig.providerName),
      _secureStorage.write(key: _kPpApiKey, value: config.llmConfig.apiKey),
    ]);
  }

  @override
  Future<OutputMode> loadOutputMode() async {
    final name = _prefs.getString(_kOutputMode);
    if (name == null) return OutputMode.copy;
    return OutputMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => OutputMode.copy,
    );
  }

  @override
  Future<void> saveOutputMode(OutputMode mode) async {
    await _prefs.setString(_kOutputMode, mode.name);
  }
}
