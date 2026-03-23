import 'package:flutter/material.dart';

import 'package:duckmouth/core/api/model_filter.dart';
import 'package:duckmouth/core/api/models_client.dart';

/// The type of model to filter for.
enum ModelType { stt, llm }

/// An autocomplete combo-box that fetches models from `/v1/models` and shows
/// them as suggestions, while always allowing free-text entry.
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
    this.hintText,
  });

  final ModelsClient modelsClient;
  final String baseUrl;
  final String apiKey;
  final ModelType modelType;
  final TextEditingController controller;
  final bool enabled;
  final String label;

  /// Optional hint text shown below the field (e.g. "This provider has no STT models").
  final String? hintText;

  @override
  State<ModelDropdown> createState() => ModelDropdownState();
}

@visibleForTesting
class ModelDropdownState extends State<ModelDropdown> {
  List<String> _models = [];
  bool _loading = false;
  String? _failureReason;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _fetchModels();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
        _models = [];
        _loading = false;
        _failureReason = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _failureReason = null;
    });

    final result = await widget.modelsClient.fetchModels(
      baseUrl: widget.baseUrl,
      apiKey: widget.apiKey,
    );

    if (!mounted) return;

    switch (result) {
      case FetchModelsFailure(:final reason):
        setState(() {
          _loading = false;
          _failureReason = reason;
          _models = [];
        });
      case FetchModelsSuccess(:final models):
        final filtered = switch (widget.modelType) {
          ModelType.stt => ModelFilter.filterStt(models),
          ModelType.llm => ModelFilter.filterLlm(models),
        };
        setState(() {
          _loading = false;
          _failureReason = null;
          _models = filtered.isEmpty ? models : filtered;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suffixIcon = _loading
        ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : null;

    final helperText = _failureReason ?? widget.hintText;

    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (textEditingValue) {
        if (_models.isEmpty) return const Iterable<String>.empty();
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return _models;
        return _models.where((m) => m.toLowerCase().contains(query));
      },
      fieldViewBuilder:
          (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: suffixIcon,
            helperText: helperText,
          ),
          enabled: widget.enabled,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
