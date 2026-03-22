import 'package:hotkey_manager/hotkey_manager.dart';

import 'package:duckmouth/features/hotkey/domain/hotkey_service.dart';

/// No-op hotkey service (no native hotkey registration in tests).
class FakeHotkeyService implements HotkeyService {
  @override
  Future<void> register(
    HotKey hotKey, {
    required void Function() onKeyDown,
    void Function()? onKeyUp,
  }) async {}

  @override
  Future<void> unregister(HotKey hotKey) async {}

  @override
  Future<void> unregisterAll() async {}

  @override
  void dispose() {}
}
