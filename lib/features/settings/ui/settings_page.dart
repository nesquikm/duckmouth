import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart' show AudioRecorder, InputDevice;

import 'package:duckmouth/core/api/models_client.dart';
import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/core/services/accessibility_service.dart';
import 'package:duckmouth/core/services/output_mode.dart';
import 'package:duckmouth/core/services/sound_config.dart';
import 'package:duckmouth/features/hotkey/domain/hotkey_config.dart';
import 'package:duckmouth/features/hotkey/ui/hotkey_recorder_dialog.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart'
    show PostProcessingConfig, PromptTemplate;
import 'package:duckmouth/features/recording/domain/audio_format_config.dart';
import 'package:duckmouth/features/settings/domain/api_config.dart';
import 'package:duckmouth/features/settings/domain/provider_preset.dart';
import 'package:duckmouth/features/settings/ui/model_dropdown.dart';
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
              :final audioFormatConfig,
              :final accessibilityStatus,
              :final selectedInputDeviceId,
            ) =>
              _SettingsForm(
                config: sttConfig,
                ppConfig: postProcessingConfig,
                outputMode: outputMode,
                hotkeyConfig: hotkeyConfig,
                soundConfig: soundConfig,
                audioFormatConfig: audioFormatConfig,
                accessibilityStatus: accessibilityStatus,
                selectedInputDeviceId: selectedInputDeviceId,
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
    required this.audioFormatConfig,
    required this.accessibilityStatus,
    this.selectedInputDeviceId,
  });

  final ApiConfig config;
  final PostProcessingConfig ppConfig;
  final OutputMode outputMode;
  final HotkeyConfig hotkeyConfig;
  final SoundConfig soundConfig;
  final AudioFormatConfig audioFormatConfig;
  final AccessibilityStatus accessibilityStatus;
  final String? selectedInputDeviceId;

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
  late PromptTemplate _ppTemplate;
  late final TextEditingController _ppPromptController;
  late final TextEditingController _ppBaseUrlController;
  late final TextEditingController _ppApiKeyController;
  late final TextEditingController _ppModelController;
  late ProviderPreset _ppSelectedPreset;

  // Hotkey
  late HotkeyConfig _hotkeyConfig;

  // Sound
  late SoundConfig _soundConfig;

  // Audio format
  late AudioFormatConfig _audioFormatConfig;
  late final TextEditingController _sampleRateController;

  // Input device
  String? _selectedDeviceId;
  List<InputDevice> _inputDevices = [];
  bool _devicesLoading = true;

  // Debounce timers for text fields
  Timer? _sttDebounce;
  Timer? _ppDebounce;
  Timer? _audioFormatDebounce;

  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _modelController = TextEditingController(text: widget.config.model);
    _selectedPreset = ProviderPreset.fromName(widget.config.providerName);

    _outputMode = widget.outputMode;

    _ppEnabled = widget.ppConfig.enabled;
    _ppTemplate = _templateForPrompt(widget.ppConfig.prompt);
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

    _audioFormatConfig = widget.audioFormatConfig;
    _sampleRateController = TextEditingController(
      text: widget.audioFormatConfig.sampleRate.toString(),
    );

    _selectedDeviceId = widget.selectedInputDeviceId;
    _loadInputDevices();

    // Wire text controller listeners for debounced auto-save
    _baseUrlController.addListener(_debounceSaveSttConfig);
    _apiKeyController.addListener(_debounceSaveSttConfig);
    _modelController.addListener(_debounceSaveSttConfig);

    _ppPromptController.addListener(_debounceSavePpConfig);
    _ppBaseUrlController.addListener(_debounceSavePpConfig);
    _ppApiKeyController.addListener(_debounceSavePpConfig);
    _ppModelController.addListener(_debounceSavePpConfig);

    _sampleRateController.addListener(_debounceSaveAudioFormatConfig);
  }

  Future<void> _loadInputDevices() async {
    try {
      final recorder = AudioRecorder();
      final devices = await recorder.listInputDevices();
      await recorder.dispose();
      if (mounted) {
        setState(() {
          _inputDevices = devices;
          _devicesLoading = false;
        });
      }
    } on Exception {
      if (mounted) {
        setState(() => _devicesLoading = false);
      }
    }
  }

  /// Only update a controller's text if the new value differs from current,
  /// preventing save loops when cubit re-emits state.
  void _setTextIfDifferent(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  @override
  void didUpdateWidget(_SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _setTextIfDifferent(_baseUrlController, widget.config.baseUrl);
      _setTextIfDifferent(_apiKeyController, widget.config.apiKey);
      _setTextIfDifferent(_modelController, widget.config.model);
      _selectedPreset = ProviderPreset.fromName(widget.config.providerName);
    }
    if (oldWidget.outputMode != widget.outputMode) {
      _outputMode = widget.outputMode;
    }
    if (oldWidget.ppConfig != widget.ppConfig) {
      _ppEnabled = widget.ppConfig.enabled;
      _ppTemplate = _templateForPrompt(widget.ppConfig.prompt);
      _setTextIfDifferent(_ppPromptController, widget.ppConfig.prompt);
      _setTextIfDifferent(
          _ppBaseUrlController, widget.ppConfig.llmConfig.baseUrl);
      _setTextIfDifferent(
          _ppApiKeyController, widget.ppConfig.llmConfig.apiKey);
      _setTextIfDifferent(_ppModelController, widget.ppConfig.llmConfig.model);
      _ppSelectedPreset =
          ProviderPreset.fromName(widget.ppConfig.llmConfig.providerName);
    }
    if (oldWidget.hotkeyConfig != widget.hotkeyConfig) {
      _hotkeyConfig = widget.hotkeyConfig;
    }
    if (oldWidget.soundConfig != widget.soundConfig) {
      _soundConfig = widget.soundConfig;
    }
    if (oldWidget.audioFormatConfig != widget.audioFormatConfig) {
      _audioFormatConfig = widget.audioFormatConfig;
      _setTextIfDifferent(
        _sampleRateController,
        widget.audioFormatConfig.sampleRate.toString(),
      );
    }
    if (oldWidget.selectedInputDeviceId != widget.selectedInputDeviceId) {
      _selectedDeviceId = widget.selectedInputDeviceId;
    }
  }

  @override
  void dispose() {
    _sttDebounce?.cancel();
    _ppDebounce?.cancel();
    _audioFormatDebounce?.cancel();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _ppPromptController.dispose();
    _ppBaseUrlController.dispose();
    _ppApiKeyController.dispose();
    _ppModelController.dispose();
    _sampleRateController.dispose();
    super.dispose();
  }

  void _onPresetChanged(ProviderPreset? preset) {
    if (preset == null) return;
    setState(() {
      _selectedPreset = preset;
    });
    context.read<SettingsCubit>().selectPreset(preset);
    // Preset change updates STT config; save immediately.
    _saveSttConfig();
  }

  void _onPpPresetChanged(ProviderPreset? preset) {
    if (preset == null) return;
    setState(() {
      _ppSelectedPreset = preset;
      if (preset != ProviderPreset.custom) {
        _ppBaseUrlController.text = preset.baseUrl;
        _ppModelController.text = preset.llmModel;
      }
    });
    _savePpConfig();
  }

  // ── Auto-save helpers ──

  void _saveSttConfig() {
    final config = ApiConfig(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      providerName: _selectedPreset.name,
    );
    context.read<SettingsCubit>().saveSettings(config);
  }

  void _savePpConfig() {
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
    context.read<SettingsCubit>().savePostProcessingConfig(ppConfig);
  }

  void _saveSoundConfig() {
    context.read<SettingsCubit>().saveSoundConfig(_soundConfig);
  }

  void _saveAudioFormatConfig() {
    context.read<SettingsCubit>().saveAudioFormatConfig(_audioFormatConfig);
  }

  // ── Debounced save triggers for text fields ──

  void _debounceSaveSttConfig() {
    _sttDebounce?.cancel();
    _sttDebounce = Timer(_debounceDuration, _saveSttConfig);
  }

  void _debounceSavePpConfig() {
    _ppDebounce?.cancel();
    _ppDebounce = Timer(_debounceDuration, _savePpConfig);
  }

  void _debounceSaveAudioFormatConfig() {
    _audioFormatDebounce?.cancel();
    _audioFormatDebounce = Timer(_debounceDuration, () {
      final rate = int.tryParse(_sampleRateController.text);
      if (rate != null && rate > 0) {
        _audioFormatConfig = _audioFormatConfig.copyWith(sampleRate: rate);
        _saveAudioFormatConfig();
      }
    });
  }

  /// Returns the matching [PromptTemplate] for the given prompt text,
  /// or [PromptTemplate.custom] if no predefined template matches.
  PromptTemplate _templateForPrompt(String prompt) {
    for (final t in PromptTemplate.values) {
      if (t != PromptTemplate.custom && t.prompt == prompt) return t;
    }
    return PromptTemplate.custom;
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
          ModelDropdown(
            modelsClient: sl<ModelsClient>(),
            baseUrl: _baseUrlController.text,
            apiKey: _apiKeyController.text,
            modelType: ModelType.stt,
            controller: _modelController,
            enabled: true,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Audio Format Section ──
          Text(
            'Audio Format',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<QualityPreset>(
            initialValue: _audioFormatConfig.preset,
            decoration: const InputDecoration(
              labelText: 'Quality Preset',
              border: OutlineInputBorder(),
            ),
            items: QualityPreset.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _audioFormatConfig =
                      _audioFormatConfig.copyWith(preset: value);
                });
                _saveAudioFormatConfig();
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            _audioFormatConfig.preset.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_audioFormatConfig.preset == QualityPreset.custom) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<AudioFormat>(
              initialValue: _audioFormatConfig.format,
              decoration: const InputDecoration(
                labelText: 'Format',
                border: OutlineInputBorder(),
              ),
              items: AudioFormat.values
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _audioFormatConfig =
                        _audioFormatConfig.copyWith(format: value);
                  });
                  _saveAudioFormatConfig();
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sampleRateController,
              decoration: const InputDecoration(
                labelText: 'Sample Rate (Hz)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Tip: WAV 16kHz is recommended for whisper.cpp and most STT APIs.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
          const SizedBox(height: 16),
          if (_devicesLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _inputDevices.any((d) => d.id == _selectedDeviceId)
                  ? _selectedDeviceId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Input Device',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('System Default'),
                ),
                ..._inputDevices.map(
                  (d) => DropdownMenuItem(value: d.id, child: Text(d.label)),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedDeviceId = value);
                context.read<SettingsCubit>().saveSelectedInputDevice(value);
              },
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
                context.read<SettingsCubit>().saveOutputMode(value);
              }
            },
          ),
          const SizedBox(height: 12),
          _AccessibilityPermissionBanner(
            status: widget.accessibilityStatus,
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
                  child: Text(_hotkeyConfig.displayLabel),
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
                final newConfig = HotkeyConfig(
                  keyCode: _hotkeyConfig.keyCode,
                  modifiers: _hotkeyConfig.modifiers,
                  mode: value,
                );
                setState(() {
                  _hotkeyConfig = newConfig;
                });
                context.read<SettingsCubit>().saveHotkeyConfig(newConfig);
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
            onChanged: (value) {
              setState(() => _soundConfig = _soundConfig.copyWith(enabled: value));
              _saveSoundConfig();
            },
          ),
          const SizedBox(height: 12),
          _VolumeSlider(
            label: 'Recording start volume',
            value: _soundConfig.startVolume,
            enabled: _soundConfig.enabled,
            onChanged: (v) {
              setState(() => _soundConfig = _soundConfig.copyWith(startVolume: v));
              _saveSoundConfig();
            },
          ),
          const SizedBox(height: 8),
          _VolumeSlider(
            label: 'Recording stop volume',
            value: _soundConfig.stopVolume,
            enabled: _soundConfig.enabled,
            onChanged: (v) {
              setState(() => _soundConfig = _soundConfig.copyWith(stopVolume: v));
              _saveSoundConfig();
            },
          ),
          const SizedBox(height: 8),
          _VolumeSlider(
            label: 'Transcription complete volume',
            value: _soundConfig.completeVolume,
            enabled: _soundConfig.enabled,
            onChanged: (v) {
              setState(() => _soundConfig = _soundConfig.copyWith(completeVolume: v));
              _saveSoundConfig();
            },
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
            onChanged: (value) {
              setState(() => _ppEnabled = value);
              _savePpConfig();
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PromptTemplate>(
            initialValue: _ppTemplate,
            decoration: const InputDecoration(
              labelText: 'Prompt Template',
              border: OutlineInputBorder(),
            ),
            items: PromptTemplate.values
                .map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                )
                .toList(),
            onChanged: _ppEnabled
                ? (value) {
                    if (value != null) {
                      setState(() {
                        _ppTemplate = value;
                        if (value != PromptTemplate.custom) {
                          _ppPromptController.text = value.prompt;
                        }
                      });
                      _savePpConfig();
                    }
                  }
                : null,
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
            onChanged: (_) {
              // If user manually edits, switch to custom template.
              if (_ppTemplate != PromptTemplate.custom) {
                setState(() => _ppTemplate = PromptTemplate.custom);
              }
            },
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
          ModelDropdown(
            modelsClient: sl<ModelsClient>(),
            baseUrl: _ppBaseUrlController.text,
            apiKey: _ppApiKeyController.text,
            modelType: ModelType.llm,
            controller: _ppModelController,
            label: 'LLM Model',
            enabled: _ppEnabled,
          ),

        ],
      ),
    );
  }

  void _showHotkeyRecorderDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return HotkeyRecorderDialog(
          currentMode: _hotkeyConfig.mode,
          onHotKeyRecorded: (config) {
            setState(() {
              _hotkeyConfig = config;
            });
            context.read<SettingsCubit>().saveHotkeyConfig(config);
          },
        );
      },
    );
  }
}

class _AccessibilityPermissionBanner extends StatelessWidget {
  const _AccessibilityPermissionBanner({required this.status});

  final AccessibilityStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor;
    final Color iconColor;
    final IconData icon;
    final String message;
    final bool showButton;

    switch (status) {
      case AccessibilityStatus.granted:
        bgColor = isDark ? const Color(0xFF1B3A1B) : Colors.green.shade50;
        iconColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        icon = Icons.check_circle;
        message = 'Accessibility permission granted — '
            'direct text insertion enabled.';
        showButton = false;
      case AccessibilityStatus.denied:
        bgColor = isDark ? const Color(0xFF3A2A0A) : Colors.orange.shade50;
        iconColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        icon = Icons.warning_amber_rounded;
        message = 'Accessibility permission required for paste-at-cursor. '
            'Grant access in System Settings \u2192 Privacy & Security '
            '\u2192 Accessibility.';
        showButton = true;
      case AccessibilityStatus.unknown:
        bgColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
        iconColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
        icon = Icons.help_outline;
        message = 'Accessibility permission status unknown.';
        showButton = true;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
          if (showButton) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                context.read<SettingsCubit>().requestAccessibilityPermission();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ],
      ),
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
