import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            SettingsLoaded(:final sttConfig, :final postProcessingConfig) =>
              _SettingsForm(
                config: sttConfig,
                ppConfig: postProcessingConfig,
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
  });

  final ApiConfig config;
  final PostProcessingConfig ppConfig;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  // STT controllers
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late ProviderPreset _selectedPreset;

  // Post-processing controllers
  late bool _ppEnabled;
  late final TextEditingController _ppPromptController;
  late final TextEditingController _ppBaseUrlController;
  late final TextEditingController _ppApiKeyController;
  late final TextEditingController _ppModelController;
  late ProviderPreset _ppSelectedPreset;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _modelController = TextEditingController(text: widget.config.model);
    _selectedPreset = ProviderPreset.fromName(widget.config.providerName);

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
    if (oldWidget.ppConfig != widget.ppConfig) {
      _ppEnabled = widget.ppConfig.enabled;
      _ppPromptController.text = widget.ppConfig.prompt;
      _ppBaseUrlController.text = widget.ppConfig.llmConfig.baseUrl;
      _ppApiKeyController.text = widget.ppConfig.llmConfig.apiKey;
      _ppModelController.text = widget.ppConfig.llmConfig.model;
      _ppSelectedPreset =
          ProviderPreset.fromName(widget.ppConfig.llmConfig.providerName);
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

    if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
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
}
