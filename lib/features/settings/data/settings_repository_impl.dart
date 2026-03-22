import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
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

/// Hotkey keys in SharedPreferences.
const _kHotkeyKeyCode = 'hotkey_key_code';
const _kHotkeyModifiers = 'hotkey_modifiers';
const _kHotkeyMode = 'hotkey_mode';

/// Sound keys in SharedPreferences.
const _kSoundEnabled = 'sound_enabled';
const _kSoundStartVolume = 'sound_start_volume';
const _kSoundStopVolume = 'sound_stop_volume';
const _kSoundCompleteVolume = 'sound_complete_volume';

/// Input device key in SharedPreferences.
const _kSelectedInputDevice = 'selected_input_device';

/// Audio format keys in SharedPreferences.
const _kAudioPreset = 'audio_preset';
const _kAudioFormat = 'audio_format';
const _kAudioSampleRate = 'audio_sample_rate';
const _kAudioBitRate = 'audio_bit_rate';

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

  @override
  Future<HotkeyConfig> loadHotkeyConfig() async {
    final keyCode = _prefs.getInt(_kHotkeyKeyCode);
    final modifiersJson = _prefs.getString(_kHotkeyModifiers);
    final modeName = _prefs.getString(_kHotkeyMode);

    if (keyCode == null) return HotkeyConfig.defaultConfig;

    final modifiers = modifiersJson != null
        ? List<String>.from(jsonDecode(modifiersJson) as List)
        : HotkeyConfig.defaultConfig.modifiers;

    final mode = modeName != null
        ? HotkeyMode.values.firstWhere(
            (m) => m.name == modeName,
            orElse: () => HotkeyMode.toggle,
          )
        : HotkeyMode.toggle;

    return HotkeyConfig(
      keyCode: keyCode,
      modifiers: modifiers,
      mode: mode,
    );
  }

  @override
  Future<void> saveHotkeyConfig(HotkeyConfig config) async {
    await Future.wait([
      _prefs.setInt(_kHotkeyKeyCode, config.keyCode),
      _prefs.setString(_kHotkeyModifiers, jsonEncode(config.modifiers)),
      _prefs.setString(_kHotkeyMode, config.mode.name),
    ]);
  }

  @override
  Future<SoundConfig> loadSoundConfig() async {
    final enabled = _prefs.getBool(_kSoundEnabled) ?? true;
    final startVolume = _prefs.getDouble(_kSoundStartVolume) ?? 1.0;
    final stopVolume = _prefs.getDouble(_kSoundStopVolume) ?? 1.0;
    final completeVolume = _prefs.getDouble(_kSoundCompleteVolume) ?? 1.0;

    return SoundConfig(
      enabled: enabled,
      startVolume: startVolume,
      stopVolume: stopVolume,
      completeVolume: completeVolume,
    );
  }

  @override
  Future<void> saveSoundConfig(SoundConfig config) async {
    await Future.wait([
      _prefs.setBool(_kSoundEnabled, config.enabled),
      _prefs.setDouble(_kSoundStartVolume, config.startVolume),
      _prefs.setDouble(_kSoundStopVolume, config.stopVolume),
      _prefs.setDouble(_kSoundCompleteVolume, config.completeVolume),
    ]);
  }

  @override
  Future<AudioFormatConfig> loadAudioFormatConfig() async {
    final presetName = _prefs.getString(_kAudioPreset);
    final formatName = _prefs.getString(_kAudioFormat);
    final sampleRate = _prefs.getInt(_kAudioSampleRate);
    final bitRate = _prefs.getInt(_kAudioBitRate);

    if (presetName == null) return const AudioFormatConfig();

    final preset = QualityPreset.values.firstWhere(
      (p) => p.name == presetName,
      orElse: () => QualityPreset.bestCompatibility,
    );

    final format = formatName != null
        ? AudioFormat.values.firstWhere(
            (f) => f.name == formatName,
            orElse: () => AudioFormat.wav,
          )
        : AudioFormat.wav;

    return AudioFormatConfig(
      preset: preset,
      format: format,
      sampleRate: sampleRate ?? 16000,
      bitRate: bitRate,
    );
  }

  @override
  Future<void> saveAudioFormatConfig(AudioFormatConfig config) async {
    await Future.wait([
      _prefs.setString(_kAudioPreset, config.preset.name),
      _prefs.setString(_kAudioFormat, config.format.name),
      _prefs.setInt(_kAudioSampleRate, config.sampleRate),
      if (config.bitRate != null)
        _prefs.setInt(_kAudioBitRate, config.bitRate!)
      else
        _prefs.remove(_kAudioBitRate),
    ]);
  }

  @override
  Future<String?> loadSelectedInputDevice() async {
    return _prefs.getString(_kSelectedInputDevice);
  }

  @override
  Future<void> saveSelectedInputDevice(String? deviceId) async {
    if (deviceId != null) {
      await _prefs.setString(_kSelectedInputDevice, deviceId);
    } else {
      await _prefs.remove(_kSelectedInputDevice);
    }
  }
}
