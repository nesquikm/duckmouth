import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/hotkey_config.dart';

/// A dialog that captures a modifier+key combo for hotkey configuration.
///
/// Replaces the broken `HotKeyRecorder` widget from `hotkey_manager` which
/// fires on bare modifier keys. This recorder waits for a non-modifier key
/// to be pressed while modifiers are held.
class HotkeyRecorderDialog extends StatefulWidget {
  const HotkeyRecorderDialog({
    super.key,
    required this.onHotKeyRecorded,
    required this.currentMode,
  });

  final void Function(HotkeyConfig config) onHotKeyRecorded;
  final HotkeyMode currentMode;

  @override
  State<HotkeyRecorderDialog> createState() => _HotkeyRecorderDialogState();
}

class _HotkeyRecorderDialogState extends State<HotkeyRecorderDialog> {
  final Set<String> _activeModifiers = {};
  final FocusNode _focusNode = FocusNode();

  /// Set of logical key IDs that are modifier keys.
  static const _modifierLogicalKeys = <int>{
    // Control
    0x00200000105, // controlLeft
    0x00200000106, // controlRight
    // Shift
    0x00200000102, // shiftLeft
    0x00200000103, // shiftRight
    // Alt/Option
    0x00200000104, // altLeft
    0x00200000107, // altRight
    // Meta/Cmd
    0x00200000108, // metaLeft
    0x00200000109, // metaRight
  };

  static bool _isModifier(LogicalKeyboardKey key) {
    return _modifierLogicalKeys.contains(key.keyId) ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  static String? _modifierName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.control) {
      return 'control';
    }
    if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.shift) {
      return 'shift';
    }
    if (key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.alt) {
      return 'alt';
    }
    if (key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.meta) {
      return 'meta';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _buildDisplayText() {
    if (_activeModifiers.isEmpty) {
      return 'Press a key combination...';
    }
    final modLabels = _activeModifiers.map((m) => switch (m) {
          'control' => 'Ctrl',
          'shift' => 'Shift',
          'alt' => 'Alt',
          'meta' => 'Cmd',
          _ => m,
        });
    return '${modLabels.join(' + ')} + ...';
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;

      // Escape cancels the dialog.
      if (logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }

      if (_isModifier(logicalKey)) {
        final name = _modifierName(logicalKey);
        if (name != null) {
          setState(() => _activeModifiers.add(name));
        }
        return KeyEventResult.handled;
      }

      // Non-modifier key pressed — record the combo if we have modifiers.
      if (_activeModifiers.isNotEmpty) {
        final usbHid = event.physicalKey.usbHidUsage;
        final config = HotkeyConfig(
          keyCode: usbHid,
          modifiers: _activeModifiers.toList(),
          mode: widget.currentMode,
        );
        widget.onHotKeyRecorded(config);
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }

      // Non-modifier without modifiers — ignore.
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      final logicalKey = event.logicalKey;
      if (_isModifier(logicalKey)) {
        final name = _modifierName(logicalKey);
        if (name != null) {
          setState(() => _activeModifiers.remove(name));
        }
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Hotkey'),
      content: SizedBox(
        width: 300,
        height: 100,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Center(
            child: Text(
              _buildDisplayText(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
