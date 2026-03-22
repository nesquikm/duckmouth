import 'package:hotkey_manager/hotkey_manager.dart';

/// Abstract interface for system-wide hotkey registration.
abstract class HotkeyService {
  /// Register a global hotkey with key-down and optional key-up handlers.
  Future<void> register(
    HotKey hotKey, {
    required void Function() onKeyDown,
    void Function()? onKeyUp,
  });

  /// Unregister a specific hotkey.
  Future<void> unregister(HotKey hotKey);

  /// Unregister all hotkeys.
  Future<void> unregisterAll();

  /// Release resources.
  void dispose();
}
