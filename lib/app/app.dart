import 'package:flutter/material.dart';
import 'package:duckmouth/core/theme/app_theme.dart';
import 'package:duckmouth/app/home_page.dart';

class DuckmouthApp extends StatelessWidget {
  const DuckmouthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duckmouth',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
