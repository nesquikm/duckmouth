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
  const SettingsLoaded({required this.sttConfig});

  final ApiConfig sttConfig;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsLoaded &&
          runtimeType == other.runtimeType &&
          sttConfig == other.sttConfig;

  @override
  int get hashCode => sttConfig.hashCode;
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
