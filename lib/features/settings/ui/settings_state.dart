import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';

/// States for the settings feature.
sealed class SettingsState {
  const SettingsState();
}

/// Settings are being loaded from storage.
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Settings have been loaded successfully.
class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.sttConfig,
    this.postProcessingConfig = const PostProcessingConfig(),
    this.outputMode = OutputMode.copy,
    this.hotkeyConfig = HotkeyConfig.defaultConfig,
  });

  final ApiConfig sttConfig;
  final PostProcessingConfig postProcessingConfig;
  final OutputMode outputMode;
  final HotkeyConfig hotkeyConfig;

  SettingsLoaded copyWith({
    ApiConfig? sttConfig,
    PostProcessingConfig? postProcessingConfig,
    OutputMode? outputMode,
    HotkeyConfig? hotkeyConfig,
  }) {
    return SettingsLoaded(
      sttConfig: sttConfig ?? this.sttConfig,
      postProcessingConfig: postProcessingConfig ?? this.postProcessingConfig,
      outputMode: outputMode ?? this.outputMode,
      hotkeyConfig: hotkeyConfig ?? this.hotkeyConfig,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsLoaded &&
          runtimeType == other.runtimeType &&
          sttConfig == other.sttConfig &&
          postProcessingConfig == other.postProcessingConfig &&
          outputMode == other.outputMode &&
          hotkeyConfig == other.hotkeyConfig;

  @override
  int get hashCode =>
      Object.hash(sttConfig, postProcessingConfig, outputMode, hotkeyConfig);
}

/// An error occurred while loading or saving settings.
class SettingsError extends SettingsState {
  const SettingsError({required this.message});

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
