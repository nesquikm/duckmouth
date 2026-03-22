import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/provider_preset.dart';
import 'package:duckmouth/features/settings/ui/settings_cubit.dart';
import 'package:duckmouth/features/settings/ui/settings_state.dart';

/// Settings page for configuring API providers.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return switch (state) {
            SettingsLoading() =>
              const Center(child: CircularProgressIndicator()),
            SettingsError(:final message) => Center(
                child: Text('Error: $message'),
              ),
            SettingsLoaded(
              :final sttConfig,
              :final postProcessingConfig,
              :final outputMode,
              :final hotkeyConfig,
              :final soundConfig,
            ) =>
              _SettingsForm(
                config: sttConfig,
                ppConfig: postProcessingConfig,
                outputMode: outputMode,
                hotkeyConfig: hotkeyConfig,
                soundConfig: soundConfig,
              ),
          };
        },
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({
    required this.config,
    required this.ppConfig,
    required this.outputMode,
    required this.hotkeyConfig,
    required this.soundConfig,
  });

  final ApiConfig config;
  final PostProcessingConfig ppConfig;
  final OutputMode outputMode;
  final HotkeyConfig hotkeyConfig;
  final SoundConfig soundConfig;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  // STT controllers
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late ProviderPreset _selectedPreset;

  // Output mode
  late OutputMode _outputMode;

  // Post-processing controllers
  late bool _ppEnabled;
  late final TextEditingController _ppPromptController;
  late final TextEditingController _ppBaseUrlController;
  late final TextEditingController _ppApiKeyController;
  late final TextEditingController _ppModelController;
  late ProviderPreset _ppSelectedPreset;

  // Hotkey
  late HotkeyConfig _hotkeyConfig;
  HotKey? _recordedHotKey;

  // Sound
  late SoundConfig _soundConfig;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _modelController = TextEditingController(text: widget.config.model);
    _selectedPreset = ProviderPreset.fromName(widget.config.providerName);

    _outputMode = widget.outputMode;

    _ppEnabled = widget.ppConfig.enabled;
    _ppPromptController = TextEditingController(text: widget.ppConfig.prompt);
    _ppBaseUrlController =
        TextEditingController(text: widget.ppConfig.llmConfig.baseUrl);
    _ppApiKeyController =
        TextEditingController(text: widget.ppConfig.llmConfig.apiKey);
    _ppModelController =
        TextEditingController(text: widget.ppConfig.llmConfig.model);
    _ppSelectedPreset =
        ProviderPreset.fromName(widget.ppConfig.llmConfig.providerName);

    _hotkeyConfig = widget.hotkeyConfig;

    _soundConfig = widget.soundConfig;
  }

  @override
  void didUpdateWidget(_SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _baseUrlController.text = widget.config.baseUrl;
      _apiKeyController.text = widget.config.apiKey;
      _modelController.text = widget.config.model;
      _selectedPreset = ProviderPreset.fromName(widget.config.providerName);
    }
    if (oldWidget.outputMode != widget.outputMode) {
      _outputMode = widget.outputMode;
    }
    if (oldWidget.ppConfig != widget.ppConfig) {
      _ppEnabled = widget.ppConfig.enabled;
      _ppPromptController.text = widget.ppConfig.prompt;
      _ppBaseUrlController.text = widget.ppConfig.llmConfig.baseUrl;
      _ppApiKeyController.text = widget.ppConfig.llmConfig.apiKey;
      _ppModelController.text = widget.ppConfig.llmConfig.model;
      _ppSelectedPreset =
          ProviderPreset.fromName(widget.ppConfig.llmConfig.providerName);
    }
    if (oldWidget.hotkeyConfig != widget.hotkeyConfig) {
      _hotkeyConfig = widget.hotkeyConfig;
    }
    if (oldWidget.soundConfig != widget.soundConfig) {
      _soundConfig = widget.soundConfig;
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _ppPromptController.dispose();
    _ppBaseUrlController.dispose();
    _ppApiKeyController.dispose();
    _ppModelController.dispose();
    super.dispose();
  }

  void _onPresetChanged(ProviderPreset? preset) {
    if (preset == null) return;
    setState(() {
      _selectedPreset = preset;
    });
    context.read<SettingsCubit>().selectPreset(preset);
  }

  void _onPpPresetChanged(ProviderPreset? preset) {
    if (preset == null) return;
    setState(() {
      _ppSelectedPreset = preset;
      if (preset != ProviderPreset.custom) {
        _ppBaseUrlController.text = preset.baseUrl;
        _ppModelController.text = preset.model;
      }
    });
  }

  Future<void> _onSave() async {
    final config = ApiConfig(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      providerName: _selectedPreset.name,
    );

    final ppConfig = PostProcessingConfig(
      enabled: _ppEnabled,
      prompt: _ppPromptController.text.trim(),
      llmConfig: ApiConfig(
        baseUrl: _ppBaseUrlController.text.trim(),
        apiKey: _ppApiKeyController.text.trim(),
        model: _ppModelController.text.trim(),
        providerName: _ppSelectedPreset.name,
      ),
    );

    final cubit = context.read<SettingsCubit>();
    final messenger = ScaffoldMessenger.of(context);

    await cubit.saveSettings(config);
    await cubit.savePostProcessingConfig(ppConfig);
    await cubit.saveOutputMode(_outputMode);
    await cubit.saveHotkeyConfig(_hotkeyConfig);
    await cubit.saveSoundConfig(_soundConfig);

    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  String _hotkeyDisplayLabel(HotkeyConfig config) {
    final modLabels = config.modifiers.map((m) => switch (m) {
          'control' => 'Ctrl',
          'shift' => 'Shift',
          'alt' => 'Alt',
          'meta' => 'Cmd',
          _ => m,
        });
    // Try to get a readable key name from keyCode.
    final keyLabel = _keyCodeToLabel(config.keyCode);
    return [...modLabels, keyLabel].join(' + ');
  }

  String _keyCodeToLabel(int keyCode) {
    // Common physical key mappings for display.
    const labels = <int, String>{
      0x00000020: 'Space',
      0x00070004: 'A',
      0x00070005: 'B',
      0x00070006: 'C',
      0x00070007: 'D',
      0x00070008: 'E',
      0x00070009: 'F',
      0x0007000a: 'G',
      0x0007000b: 'H',
      0x0007000c: 'I',
      0x0007000d: 'J',
      0x0007000e: 'K',
      0x0007000f: 'L',
      0x00070010: 'M',
      0x00070011: 'N',
      0x00070012: 'O',
      0x00070013: 'P',
      0x00070014: 'Q',
      0x00070015: 'R',
      0x00070016: 'S',
      0x00070017: 'T',
      0x00070018: 'U',
      0x00070019: 'V',
      0x0007001a: 'W',
      0x0007001b: 'X',
      0x0007001c: 'Y',
      0x0007001d: 'Z',
    };
    return labels[keyCode] ?? 'Key(0x${keyCode.toRadixString(16)})';
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _selectedPreset == ProviderPreset.custom;
    final isPpCustom = _ppSelectedPreset == ProviderPreset.custom;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── STT Provider Section ──
          Text('STT Provider', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProviderPreset>(
            initialValue: _selectedPreset,
            decoration: const InputDecoration(
              labelText: 'Provider',
              border: OutlineInputBorder(),
            ),
            items: ProviderPreset.values
                .map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                )
                .toList(),
            onChanged: _onPresetChanged,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'API Endpoint URL',
              border: OutlineInputBorder(),
            ),
            enabled: isCustom,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
            enabled: isCustom,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Output Mode Section ──
          Text(
            'Output Mode',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<OutputMode>(
            initialValue: _outputMode,
            decoration: const InputDecoration(
              labelText: 'After transcription',
              border: OutlineInputBorder(),
            ),
            items: OutputMode.values
                .map(
                  (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _outputMode = value);
              }
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Global Hotkey Section ──
          Text(
            'Global Hotkey',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Shortcut',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _recordedHotKey != null
                        ? _hotkeyDisplayLabel(
                            HotkeyConfig.fromHotKey(
                              _recordedHotKey!,
                              mode: _hotkeyConfig.mode,
                            ),
                          )
                        : _hotkeyDisplayLabel(_hotkeyConfig),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: _showHotkeyRecorderDialog,
                child: const Text('Record'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<HotkeyMode>(
            initialValue: _hotkeyConfig.mode,
            decoration: const InputDecoration(
              labelText: 'Hotkey Mode',
              border: OutlineInputBorder(),
            ),
            items: HotkeyMode.values
                .map(
                  (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _hotkeyConfig = HotkeyConfig(
                    keyCode: _hotkeyConfig.keyCode,
                    modifiers: _hotkeyConfig.modifiers,
                    mode: value,
                  );
                });
              }
            },
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Sound Feedback Section ──
          Text(
            'Sound Feedback',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable sound feedback'),
            subtitle: const Text(
              'Play sounds for recording and transcription events',
            ),
            value: _soundConfig.enabled,
            onChanged: (value) =>
                setState(() => _soundConfig = _soundConfig.copyWith(enabled: value)),
          ),
          const SizedBox(height: 12),
          _VolumeSlider(
            label: 'Recording start volume',
            value: _soundConfig.startVolume,
            enabled: _soundConfig.enabled,
            onChanged: (v) =>
                setState(() => _soundConfig = _soundConfig.copyWith(startVolume: v)),
          ),
          const SizedBox(height: 8),
          _VolumeSlider(
            label: 'Recording stop volume',
            value: _soundConfig.stopVolume,
            enabled: _soundConfig.enabled,
            onChanged: (v) =>
                setState(() => _soundConfig = _soundConfig.copyWith(stopVolume: v)),
          ),
          const SizedBox(height: 8),
          _VolumeSlider(
            label: 'Transcription complete volume',
            value: _soundConfig.completeVolume,
            enabled: _soundConfig.enabled,
            onChanged: (v) =>
                setState(() => _soundConfig = _soundConfig.copyWith(completeVolume: v)),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Post-Processing Section ──
          Text(
            'Post-Processing (LLM)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable post-processing'),
            subtitle: const Text(
              'Process transcription results with an LLM',
            ),
            value: _ppEnabled,
            onChanged: (value) => setState(() => _ppEnabled = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ppPromptController,
            decoration: const InputDecoration(
              labelText: 'System Prompt',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            enabled: _ppEnabled,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ProviderPreset>(
            initialValue: _ppSelectedPreset,
            decoration: const InputDecoration(
              labelText: 'LLM Provider',
              border: OutlineInputBorder(),
            ),
            items: ProviderPreset.values
                .map(
                  (p) => DropdownMenuItem(value: p, child: Text(p.label)),
                )
                .toList(),
            onChanged: _ppEnabled ? _onPpPresetChanged : null,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ppBaseUrlController,
            decoration: const InputDecoration(
              labelText: 'LLM API Endpoint URL',
              border: OutlineInputBorder(),
            ),
            enabled: _ppEnabled && isPpCustom,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ppApiKeyController,
            decoration: const InputDecoration(
              labelText: 'LLM API Key',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            enabled: _ppEnabled,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ppModelController,
            decoration: const InputDecoration(
              labelText: 'LLM Model',
              border: OutlineInputBorder(),
            ),
            enabled: _ppEnabled && isPpCustom,
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _onSave,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _showHotkeyRecorderDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Record Hotkey'),
          content: SizedBox(
            width: 300,
            height: 100,
            child: Center(
              child: HotKeyRecorder(
                onHotKeyRecorded: (hotKey) {
                  setState(() {
                    _recordedHotKey = hotKey;
                    _hotkeyConfig = HotkeyConfig.fromHotKey(
                      hotKey,
                      mode: _hotkeyConfig.mode,
                    );
                  });
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: Slider(
            value: value,
            onChanged: enabled ? onChanged : null,
            divisions: 10,
            label: '${(value * 100).round()}%',
          ),
        ),
      ],
    );
  }
}
