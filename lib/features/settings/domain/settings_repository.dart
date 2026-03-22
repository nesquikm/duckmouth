import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';

/// Interface for persisting and retrieving application settings.
abstract class SettingsRepository {
  /// Load the saved STT API configuration.
  ///
  /// Returns `null` if no settings have been saved yet.
  Future<ApiConfig?> loadSttConfig();

  /// Persist the given STT API configuration.
  Future<void> saveSttConfig(ApiConfig config);

  /// Load the saved post-processing configuration.
  Future<PostProcessingConfig> loadPostProcessingConfig();

  /// Persist the given post-processing configuration.
  Future<void> savePostProcessingConfig(PostProcessingConfig config);

  /// Load the saved output mode.
  Future<OutputMode> loadOutputMode();

  /// Persist the given output mode.
  Future<void> saveOutputMode(OutputMode mode);

  /// Load the saved hotkey configuration.
  Future<HotkeyConfig> loadHotkeyConfig();

  /// Persist the given hotkey configuration.
  Future<void> saveHotkeyConfig(HotkeyConfig config);

  /// Load the saved sound configuration.
  Future<SoundConfig> loadSoundConfig();

  /// Persist the given sound configuration.
  Future<void> saveSoundConfig(SoundConfig config);
}
