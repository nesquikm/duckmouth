import 'package:system_tray/system_tray.dart';

class SystemTrayManager {
  SystemTray? _systemTray;

  Future<void> init() async {
    _systemTray = SystemTray();
    await _systemTray!.initSystemTray(
      title: 'Duckmouth',
      iconPath: 'assets/tray_icon.png',
      toolTip: 'Duckmouth - Speech to Text',
    );

    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Show', onClicked: (menuItem) {}),
      MenuSeparator(),
      MenuItemLabel(label: 'Quit', onClicked: (menuItem) {}),
    ]);
    await _systemTray!.setContextMenu(menu);
  }

  void dispose() {
    _systemTray?.destroy();
  }
}
