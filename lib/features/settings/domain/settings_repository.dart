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
}
