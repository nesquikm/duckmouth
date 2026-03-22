import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/hotkey_config.dart';
import '../domain/hotkey_service.dart';
import 'hotkey_state.dart';

/// Cubit that manages global hotkey registration and recording triggers.
class HotkeyCubit extends Cubit<HotkeyState> {
  HotkeyCubit({required HotkeyService service})
      : _service = service,
        super(const HotkeyIdle());

  final HotkeyService _service;

  /// Whether recording is currently active (for toggle mode).
  bool _isRecording = false;

  /// Visible for testing.
  bool get isRecording => _isRecording;

  /// Register a hotkey with the given [config].
  Future<void> registerHotkey(HotkeyConfig config) async {
    try {
      // Unregister any existing hotkey first.
      await _service.unregisterAll();
      _isRecording = false;

      final hotKey = config.toHotKey();

      await _service.register(
        hotKey,
        onKeyDown: () => _onKeyDown(config),
        onKeyUp: config.mode == HotkeyMode.pushToTalk
            ? () => _onKeyUp(config)
            : null,
      );

      _tryEmit(HotkeyRegistered(config: config));
    } on Exception catch (e) {
      _tryEmit(HotkeyError(message: 'Failed to register hotkey: $e'));
    }
  }

  /// Unregister the current hotkey.
  Future<void> unregisterHotkey() async {
    try {
      await _service.unregisterAll();
      _isRecording = false;
      _tryEmit(const HotkeyIdle());
    } on Exception catch (e) {
      _tryEmit(HotkeyError(message: 'Failed to unregister hotkey: $e'));
    }
  }

  void _onKeyDown(HotkeyConfig config) {
    switch (config.mode) {
      case HotkeyMode.pushToTalk:
        _isRecording = true;
        _tryEmit(HotkeyActionStart(config: config));
      case HotkeyMode.toggle:
        if (_isRecording) {
          _isRecording = false;
          _tryEmit(HotkeyActionStop(config: config));
        } else {
          _isRecording = true;
          _tryEmit(HotkeyActionStart(config: config));
        }
    }
  }

  void _onKeyUp(HotkeyConfig config) {
    if (config.mode == HotkeyMode.pushToTalk && _isRecording) {
      _isRecording = false;
      _tryEmit(HotkeyActionStop(config: config));
    }
  }

  /// Notify the cubit that recording has stopped externally (e.g. via UI).
  void resetRecordingState() {
    _isRecording = false;
  }

  void _tryEmit(HotkeyState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  @override
  Future<void> close() async {
    await _service.unregisterAll();
    return super.close();
  }
}
