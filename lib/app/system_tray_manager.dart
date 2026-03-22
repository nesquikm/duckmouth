import 'dart:ui';

import 'package:system_tray/system_tray.dart';

/// Manages the macOS system tray icon, tooltip, and context menu.
class SystemTrayManager {
  SystemTray? _systemTray;
  VoidCallback? _onShow;
  VoidCallback? _onQuit;

  Future<void> init() async {
    _systemTray = SystemTray();
    await _systemTray!.initSystemTray(
      title: 'Duckmouth',
      iconPath: 'assets/tray_icon.png',
      toolTip: 'Duckmouth — Idle',
    );

    await _rebuildMenu();
  }

  /// Set the callback invoked when the user clicks "Show" in the tray menu.
  void setOnShow(VoidCallback callback) {
    _onShow = callback;
  }

  /// Set the callback invoked when the user clicks "Quit" in the tray menu.
  void setOnQuit(VoidCallback callback) {
    _onQuit = callback;
  }

  /// Update the tooltip shown when hovering over the tray icon.
  void updateToolTip(String status) {
    _systemTray?.setToolTip('Duckmouth — $status');
  }

  /// Update the tray menu to include recent transcription snippets.
  Future<void> updateRecentTranscriptions(List<String> snippets) async {
    await _rebuildMenu(recentSnippets: snippets);
  }

  Future<void> _rebuildMenu({List<String> recentSnippets = const []}) async {
    final menu = Menu();
    final items = <MenuItemBase>[
      MenuItemLabel(
        label: 'Show',
        onClicked: (menuItem) => _onShow?.call(),
      ),
      MenuSeparator(),
    ];

    if (recentSnippets.isNotEmpty) {
      for (final snippet in recentSnippets.take(3)) {
        // Truncate long snippets for the menu.
        final label =
            snippet.length > 60 ? '${snippet.substring(0, 57)}...' : snippet;
        items.add(MenuItemLabel(label: label, onClicked: (menuItem) {}));
      }
      items.add(MenuSeparator());
    }

    items.add(
      MenuItemLabel(
        label: 'Quit',
        onClicked: (menuItem) => _onQuit?.call(),
      ),
    );

    await menu.buildFrom(items);
    await _systemTray!.setContextMenu(menu);
  }

  void dispose() {
    _systemTray?.destroy();
  }
}
