import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/app/home_page.dart';
import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/core/theme/app_theme.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';

class DuckmouthApp extends StatelessWidget {
  const DuckmouthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsCubit>()..loadSettings(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        buildWhen: (previous, current) {
          final prevTheme =
              previous is SettingsLoaded ? previous.themeMode : null;
          final currTheme =
              current is SettingsLoaded ? current.themeMode : null;
          return prevTheme != currTheme;
        },
        builder: (context, state) {
          final themeMode = state is SettingsLoaded
              ? state.themeMode.toFlutterThemeMode()
              : ThemeMode.system;
          return MaterialApp(
            title: 'Duckmouth',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
