import 'package:flutter/material.dart';
import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/app/system_tray_manager.dart';
import 'package:duckmouth/core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();

  final trayManager = SystemTrayManager();
  await trayManager.init();

  runApp(const DuckmouthApp());
}
