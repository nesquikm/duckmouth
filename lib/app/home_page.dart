import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_cubit.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_state.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_state.dart';
import 'package:duckmouth/features/recording/ui/recording_controls.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/recording/ui/recording_state.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/settings/ui/settings_page.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';
import 'package:duckmouth/features/transcription/ui/transcription_display.dart';
import 'package:duckmouth/features/transcription/ui/transcription_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<RecordingCubit>()),
        BlocProvider(create: (_) => sl<TranscriptionCubit>()),
        BlocProvider(create: (_) => sl<SettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => sl<PostProcessingCubit>()),
        BlocProvider(create: (_) => sl<HotkeyCubit>()),
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
          updateLlmClient(state.postProcessingConfig.llmConfig);
          context
              .read<PostProcessingCubit>()
              .updateConfig(state.postProcessingConfig);

          // Register the hotkey whenever settings are loaded/saved.
          context.read<HotkeyCubit>().registerHotkey(state.hotkeyConfig);
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

void _handleOutput(BuildContext context, String text) {
  final settingsState = context.read<SettingsCubit>().state;
  final outputMode = settingsState is SettingsLoaded
      ? settingsState.outputMode
      : OutputMode.copy;

  final clipboard = sl<ClipboardService>();

  switch (outputMode) {
    case OutputMode.copy:
      clipboard.copyToClipboard(text);
    case OutputMode.paste:
    case OutputMode.both:
      clipboard.pasteAtCursor(text);
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RecordingCubit, RecordingState>(
          listener: (context, state) {
            if (state is RecordingComplete) {
              context.read<TranscriptionCubit>().transcribe(state.filePath);
            }
            // Reset hotkey recording state when recording stops externally.
            if (state is RecordingIdle || state is RecordingComplete) {
              context.read<HotkeyCubit>().resetRecordingState();
            }
          },
        ),
        BlocListener<TranscriptionCubit, TranscriptionState>(
          listener: (context, state) {
            if (state is TranscriptionSuccess) {
              context.read<PostProcessingCubit>().process(state.text);
            }
          },
        ),
        BlocListener<PostProcessingCubit, PostProcessingState>(
          listener: (context, state) {
            final String? textToOutput;
            if (state is PostProcessingSuccess) {
              textToOutput = state.processedText;
            } else if (state is PostProcessingDisabled) {
              // Post-processing is off — use the raw transcription text.
              final transcriptionState =
                  context.read<TranscriptionCubit>().state;
              textToOutput = transcriptionState is TranscriptionSuccess
                  ? transcriptionState.text
                  : null;
            } else {
              textToOutput = null;
            }

            if (textToOutput != null) {
              _handleOutput(context, textToOutput);
            }
          },
        ),
        BlocListener<HotkeyCubit, HotkeyState>(
          listener: (context, state) {
            if (state is HotkeyActionStart) {
              context.read<RecordingCubit>().startRecording();
            } else if (state is HotkeyActionStop) {
              context.read<RecordingCubit>().stopRecording();
            }
          },
        ),
      ],
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
