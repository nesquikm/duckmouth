import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';

/// Keys used in SharedPreferences.
const _kBaseUrl = 'stt_base_url';
const _kModel = 'stt_model';
const _kProviderName = 'stt_provider_name';

/// Key used in FlutterSecureStorage.
const _kApiKey = 'stt_api_key';

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
}
