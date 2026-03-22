import 'package:hotkey_manager/hotkey_manager.dart';

import '../domain/hotkey_service.dart';

/// [HotkeyService] implementation backed by [HotKeyManager].
class HotkeyServiceImpl implements HotkeyService {
  HotkeyServiceImpl({HotKeyManager? manager})
      : _manager = manager ?? HotKeyManager.instance;

  final HotKeyManager _manager;

  @override
  Future<void> register(
    HotKey hotKey, {
    required void Function() onKeyDown,
    void Function()? onKeyUp,
  }) async {
    await _manager.register(
      hotKey,
      keyDownHandler: (_) => onKeyDown(),
      keyUpHandler: onKeyUp != null ? (_) => onKeyUp() : null,
    );
  }

  @override
  Future<void> unregister(HotKey hotKey) async {
    await _manager.unregister(hotKey);
  }

  @override
  Future<void> unregisterAll() async {
    await _manager.unregisterAll();
  }

  @override
  void dispose() {
    _manager.unregisterAll();
  }
}
