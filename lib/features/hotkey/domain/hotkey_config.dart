import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// Recording mode triggered by the hotkey.
enum HotkeyMode {
  /// Hold key to record, release to stop.
  pushToTalk,

  /// Press to start recording, press again to stop.
  toggle;

  String get label => switch (this) {
        HotkeyMode.pushToTalk => 'Push-to-Talk',
        HotkeyMode.toggle => 'Toggle',
      };
}

/// Configuration for a global hotkey binding.
@immutable
class HotkeyConfig {
  const HotkeyConfig({
    required this.keyCode,
    required this.modifiers,
    this.mode = HotkeyMode.toggle,
  });

  /// The physical key for the hotkey.
  final int keyCode;

  /// Modifier keys (as [HotKeyModifier] name strings for serialisation).
  final List<String> modifiers;

  /// Whether the hotkey acts as push-to-talk or toggle.
  final HotkeyMode mode;

  /// Default hotkey: Ctrl+Shift+Space.
  static const HotkeyConfig defaultConfig = HotkeyConfig(
    keyCode: 0x0007002C, // PhysicalKeyboardKey.space USB HID usage
    modifiers: ['control', 'shift'],
    mode: HotkeyMode.toggle,
  );

  /// Build a [HotKey] instance from this config.
  HotKey toHotKey() {
    final key = PhysicalKeyboardKey(keyCode);
    final mods = modifiers.map(_modifierFromName).toList();
    return HotKey(key: key, modifiers: mods, scope: HotKeyScope.system);
  }

  static HotKeyModifier _modifierFromName(String name) {
    return switch (name) {
      'alt' => HotKeyModifier.alt,
      'control' => HotKeyModifier.control,
      'shift' => HotKeyModifier.shift,
      'meta' => HotKeyModifier.meta,
      _ => HotKeyModifier.control,
    };
  }

  /// Create config from a [HotKey].
  factory HotkeyConfig.fromHotKey(HotKey hotKey, {HotkeyMode mode = HotkeyMode.toggle}) {
    return HotkeyConfig(
      keyCode: hotKey.physicalKey.usbHidUsage,
      modifiers: (hotKey.modifiers ?? []).map(_modifierToName).toList(),
      mode: mode,
    );
  }

  static String _modifierToName(HotKeyModifier mod) {
    return switch (mod) {
      HotKeyModifier.alt => 'alt',
      HotKeyModifier.control => 'control',
      HotKeyModifier.shift => 'shift',
      HotKeyModifier.meta => 'meta',
      _ => 'control',
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotkeyConfig &&
          runtimeType == other.runtimeType &&
          keyCode == other.keyCode &&
          listEquals(modifiers, other.modifiers) &&
          mode == other.mode;

  @override
  int get hashCode => Object.hash(keyCode, Object.hashAll(modifiers), mode);
}
