import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/features/recording/ui/recording_controls.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/recording/ui/recording_state.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/settings/ui/settings_page.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';
import 'package:duckmouth/features/transcription/ui/transcription_display.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RecordingCubit>()),
        BlocProvider(create: (_) => sl<TranscriptionCubit>()),
        BlocProvider(create: (_) => sl<SettingsCubit>()..loadSettings()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Duckmouth'),
          actions: const [_SettingsButton()],
        ),
        body: const _HomeBody(),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state is SettingsLoaded) {
          updateOpenAiClient(state.sttConfig);
        }
      },
      child: IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: context.read<SettingsCubit>(),
                child: const SettingsPage(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecordingCubit, RecordingState>(
      listener: (context, state) {
        if (state is RecordingComplete) {
          context.read<TranscriptionCubit>().transcribe(state.filePath);
        }
      },
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RecordingControls(),
            SizedBox(height: 24),
            TranscriptionDisplay(),
          ],
        ),
      ),
    );
  }
}
