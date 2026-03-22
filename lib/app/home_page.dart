import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:duckmouth/app/system_tray_manager.dart';
import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/clipboard_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/core/services/sound_service.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';
import 'package:duckmouth/features/history/ui/history_cubit.dart';
import 'package:duckmouth/features/history/ui/history_page.dart';
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
        BlocProvider(create: (_) => sl<HistoryCubit>()..loadHistory()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Duckmouth'),
          actions: const [_HistoryButton(), _SettingsButton()],
        ),
        body: const _HomeBody(),
      ),
    );
  }
}

class _HistoryButton extends StatelessWidget {
  const _HistoryButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.history),
      tooltip: 'History',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: context.read<HistoryCubit>(),
              child: const HistoryPage(),
            ),
          ),
        );
      },
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

          // Update recording format config and input device.
          context
              .read<RecordingCubit>()
              ..updateFormatConfig(state.audioFormatConfig)
              ..updateSelectedDevice(state.selectedInputDeviceId);

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

SoundConfig _currentSoundConfig(BuildContext context) {
  final settingsState = context.read<SettingsCubit>().state;
  return settingsState is SettingsLoaded
      ? settingsState.soundConfig
      : const SoundConfig();
}

final _log = Logger('HomePage');

void _handleOutput(BuildContext context, String text) {
  final settingsState = context.read<SettingsCubit>().state;
  final outputMode = settingsState is SettingsLoaded
      ? settingsState.outputMode
      : OutputMode.copy;

  _log.info('Output: mode=$outputMode, ${text.length} chars');
  final clipboard = sl<ClipboardService>();

  switch (outputMode) {
    case OutputMode.copy:
      clipboard.copyToClipboard(text);
    case OutputMode.paste:
    case OutputMode.both:
      clipboard.pasteAtCursor(text);
  }
}

void _updateTrayStatus(String status) {
  if (sl.isRegistered<SystemTrayManager>()) {
    sl<SystemTrayManager>().updateToolTip(status);
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SettingsCubit>().checkAccessibilityPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RecordingCubit, RecordingState>(
          listener: (context, state) {
            if (state is RecordingInProgress &&
                state.duration == Duration.zero) {
              final sc = _currentSoundConfig(context);
              if (sc.enabled) {
                sl<SoundService>()
                    .playRecordingStart(volume: sc.startVolume);
              }
              _updateTrayStatus('Recording...');
            }
            if (state is RecordingComplete) {
              final sc = _currentSoundConfig(context);
              if (sc.enabled) {
                sl<SoundService>()
                    .playRecordingStop(volume: sc.stopVolume);
              }
              _updateTrayStatus('Transcribing...');
              context.read<TranscriptionCubit>().transcribe(state.filePath);
            }
            if (state is RecordingError) {
              _updateTrayStatus('Error');
            }
            // Reset hotkey recording state when recording stops externally.
            if (state is RecordingIdle || state is RecordingComplete) {
              context.read<HotkeyCubit>().resetRecordingState();
            }
            if (state is RecordingIdle) {
              _updateTrayStatus('Idle');
            }
          },
        ),
        BlocListener<TranscriptionCubit, TranscriptionState>(
          listener: (context, state) {
            if (state is TranscriptionSuccess) {
              context.read<PostProcessingCubit>().process(state.text);
            }
            if (state is TranscriptionError) {
              _updateTrayStatus('Error');
            }
            if (state is TranscriptionIdle) {
              _updateTrayStatus('Idle');
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
              final sc = _currentSoundConfig(context);
              if (sc.enabled) {
                sl<SoundService>().playTranscriptionComplete(
                  volume: sc.completeVolume,
                );
              }
              _handleOutput(context, textToOutput);
              _updateTrayStatus('Done');

              // Save to history.
              final transcriptionState =
                  context.read<TranscriptionCubit>().state;
              final rawText = transcriptionState is TranscriptionSuccess
                  ? transcriptionState.text
                  : textToOutput;
              final processedText = state is PostProcessingSuccess
                  ? state.processedText
                  : null;
              context.read<HistoryCubit>().addEntry(
                    TranscriptionEntry(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      rawText: rawText,
                      processedText: processedText,
                      timestamp: DateTime.now(),
                    ),
                  );

              // Update tray with recent transcription.
              _updateTrayRecentTranscription(textToOutput);
            }

            if (state is PostProcessingError) {
              _updateTrayStatus('Processing error');
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            BlocBuilder<SettingsCubit, SettingsState>(
              buildWhen: (previous, current) {
                final prevStatus = previous is SettingsLoaded
                    ? previous.accessibilityStatus
                    : null;
                final currStatus = current is SettingsLoaded
                    ? current.accessibilityStatus
                    : null;
                return prevStatus != currStatus;
              },
              builder: (context, state) {
                if (state is SettingsLoaded &&
                    state.accessibilityStatus != AccessibilityStatus.granted) {
                  return const _AccessibilityBanner();
                }
                return const SizedBox.shrink();
              },
            ),
            const Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RecordingControls(),
                      SizedBox(height: 24),
                      TranscriptionDisplay(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keep a small list of recent transcription snippets for the tray menu.
final List<String> _recentSnippets = [];

void _updateTrayRecentTranscription(String text) {
  if (!sl.isRegistered<SystemTrayManager>()) return;

  _recentSnippets.insert(0, text);
  if (_recentSnippets.length > 3) {
    _recentSnippets.removeRange(3, _recentSnippets.length);
  }
  sl<SystemTrayManager>().updateRecentTranscriptions(_recentSnippets);
}

class _AccessibilityBanner extends StatelessWidget {
  const _AccessibilityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Accessibility permission is required to insert text at the cursor. '
              'Grant access in System Settings \u2192 Privacy & Security \u2192 Accessibility.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              context.read<SettingsCubit>().requestAccessibilityPermission();
            },
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }
}
