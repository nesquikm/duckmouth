import 'dart:io';

import 'package:flutter/material.dart';
import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/app/system_tray_manager.dart';
import 'package:duckmouth/core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();

  final trayManager = SystemTrayManager();
  sl.registerSingleton<SystemTrayManager>(trayManager);
  await trayManager.init();

  trayManager.setOnShow(() {
    // Bring the app window to front. On macOS this activates the application.
    // The WidgetsBinding handles the actual window management.
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
  });

  trayManager.setOnQuit(() {
    trayManager.dispose();
    exit(0);
  });

  runApp(const DuckmouthApp());
}
