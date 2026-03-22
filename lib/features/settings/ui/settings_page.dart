import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            SettingsLoaded(:final sttConfig) =>
              _SettingsForm(config: sttConfig),
          };
        },
      ),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm({required this.config});

  final ApiConfig config;

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  late ProviderPreset _selectedPreset;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.config.baseUrl);
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _modelController = TextEditingController(text: widget.config.model);
    _selectedPreset = ProviderPreset.fromName(widget.config.providerName);
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
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onPresetChanged(ProviderPreset? preset) {
    if (preset == null) return;
    setState(() {
      _selectedPreset = preset;
    });
    context.read<SettingsCubit>().selectPreset(preset);
  }

  Future<void> _onSave() async {
    final config = ApiConfig(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      providerName: _selectedPreset.name,
    );
    await context.read<SettingsCubit>().saveSettings(config);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = _selectedPreset == ProviderPreset.custom;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
