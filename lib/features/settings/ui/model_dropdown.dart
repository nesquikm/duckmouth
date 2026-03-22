import 'package:flutter/material.dart';

import 'package:duckmouth/core/api/model_filter.dart';
import 'package:duckmouth/core/api/models_client.dart';

/// The type of model to filter for.
enum ModelType { stt, llm }

/// A dropdown that fetches models from `/v1/models` and shows them in a
/// dropdown. Falls back to a free-text [TextField] on error.
class ModelDropdown extends StatefulWidget {
  const ModelDropdown({
    super.key,
    required this.modelsClient,
    required this.baseUrl,
    required this.apiKey,
    required this.modelType,
    required this.controller,
    required this.enabled,
    this.label = 'Model',
  });

  final ModelsClient modelsClient;
  final String baseUrl;
  final String apiKey;
  final ModelType modelType;
  final TextEditingController controller;
  final bool enabled;
  final String label;

  @override
  State<ModelDropdown> createState() => ModelDropdownState();
}

@visibleForTesting
class ModelDropdownState extends State<ModelDropdown> {
  List<String>? _models;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _fetchModels();
  }

  @override
  void didUpdateWidget(ModelDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.baseUrl != widget.baseUrl ||
        oldWidget.apiKey != widget.apiKey) {
      _fetchModels();
    }
  }

  Future<void> _fetchModels() async {
    if (widget.baseUrl.isEmpty || widget.apiKey.isEmpty) {
      setState(() {
        _models = null;
        _loading = false;
        _failed = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });

    final all = await widget.modelsClient.fetchModels(
      baseUrl: widget.baseUrl,
      apiKey: widget.apiKey,
    );

    if (!mounted) return;

    if (all.isEmpty) {
      setState(() {
        _loading = false;
        _failed = true;
        _models = null;
      });
      return;
    }

    final filtered = switch (widget.modelType) {
      ModelType.stt => ModelFilter.filterStt(all),
      ModelType.llm => ModelFilter.filterLlm(all),
    };

    setState(() {
      _loading = false;
      _failed = false;
      _models = filtered.isEmpty ? all : filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        enabled: false,
      );
    }

    // Show dropdown if we have models.
    if (_models != null && _models!.isNotEmpty) {
      final currentValue = widget.controller.text;
      final hasMatch = _models!.contains(currentValue);

      return DropdownButtonFormField<String>(
        initialValue: hasMatch ? currentValue : null,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        items: [
          if (!hasMatch && currentValue.isNotEmpty)
            DropdownMenuItem(
              value: currentValue,
              child: Text('$currentValue (current)'),
            ),
          ..._models!.map(
            (m) => DropdownMenuItem(value: m, child: Text(m)),
          ),
        ],
        onChanged: widget.enabled
            ? (value) {
                if (value != null) {
                  widget.controller.text = value;
                }
              }
            : null,
      );
    }

    // Fallback: free-text field.
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        helperText: _failed ? 'Could not load models — type manually' : null,
      ),
      enabled: widget.enabled,
    );
  }
}
