import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/settings_repository.dart';

/// In-memory settings repository for integration tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({PostProcessingConfig? initialPpConfig})
      : _ppConfig = initialPpConfig ?? const PostProcessingConfig();

  ApiConfig? _sttConfig;
  PostProcessingConfig _ppConfig;
  OutputMode _outputMode = OutputMode.copy;
  HotkeyConfig _hotkeyConfig = HotkeyConfig.defaultConfig;
  SoundConfig _soundConfig = const SoundConfig();
  AudioFormatConfig _audioFormatConfig = const AudioFormatConfig();
  String? _selectedInputDevice;

  @override
  Future<ApiConfig?> loadSttConfig() async => _sttConfig;

  @override
  Future<void> saveSttConfig(ApiConfig config) async {
    _sttConfig = config;
  }

  @override
  Future<PostProcessingConfig> loadPostProcessingConfig() async => _ppConfig;

  @override
  Future<void> savePostProcessingConfig(PostProcessingConfig config) async {
    _ppConfig = config;
  }

  @override
  Future<OutputMode> loadOutputMode() async => _outputMode;

  @override
  Future<void> saveOutputMode(OutputMode mode) async {
    _outputMode = mode;
  }

  @override
  Future<HotkeyConfig> loadHotkeyConfig() async => _hotkeyConfig;

  @override
  Future<void> saveHotkeyConfig(HotkeyConfig config) async {
    _hotkeyConfig = config;
  }

  @override
  Future<SoundConfig> loadSoundConfig() async => _soundConfig;

  @override
  Future<void> saveSoundConfig(SoundConfig config) async {
    _soundConfig = config;
  }

  @override
  Future<AudioFormatConfig> loadAudioFormatConfig() async => _audioFormatConfig;

  @override
  Future<void> saveAudioFormatConfig(AudioFormatConfig config) async {
    _audioFormatConfig = config;
  }

  @override
  Future<String?> loadSelectedInputDevice() async => _selectedInputDevice;

  @override
  Future<void> saveSelectedInputDevice(String? deviceId) async {
    _selectedInputDevice = deviceId;
  }
}
