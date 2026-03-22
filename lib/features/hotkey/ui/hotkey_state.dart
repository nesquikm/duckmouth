import 'package:flutter/foundation.dart';

import '../domain/hotkey_config.dart';

/// States for the hotkey feature.
@immutable
sealed class HotkeyState {
  const HotkeyState();
}

/// No hotkey registered.
class HotkeyIdle extends HotkeyState {
  const HotkeyIdle();

  @override
  bool operator ==(Object other) => other is HotkeyIdle;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// A hotkey is actively registered and listening.
class HotkeyRegistered extends HotkeyState {
  const HotkeyRegistered({required this.config});

  final HotkeyConfig config;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotkeyRegistered &&
          runtimeType == other.runtimeType &&
          config == other.config;

  @override
  int get hashCode => config.hashCode;
}

/// The hotkey was triggered — start recording.
class HotkeyActionStart extends HotkeyState {
  const HotkeyActionStart({required this.config});

  final HotkeyConfig config;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotkeyActionStart &&
          runtimeType == other.runtimeType &&
          config == other.config;

  @override
  int get hashCode => config.hashCode;
}

/// The hotkey was triggered — stop recording.
class HotkeyActionStop extends HotkeyState {
  const HotkeyActionStop({required this.config});

  final HotkeyConfig config;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotkeyActionStop &&
          runtimeType == other.runtimeType &&
          config == other.config;

  @override
  int get hashCode => config.hashCode;
}

/// An error occurred while registering or handling the hotkey.
class HotkeyError extends HotkeyState {
  const HotkeyError({required this.message});

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotkeyError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
