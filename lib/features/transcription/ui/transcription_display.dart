import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_state.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'transcription_cubit.dart';
import 'transcription_state.dart';

/// Widget that displays the transcription result and optional post-processing.
class TranscriptionDisplay extends StatelessWidget {
  const TranscriptionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TranscriptionCubit, TranscriptionState>(
      builder: (context, state) {
        return switch (state) {
          TranscriptionIdle() => const SizedBox.shrink(),
          TranscriptionLoading() => const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Transcribing...'),
                ],
              ),
            ),
          TranscriptionSuccess(:final text) =>
            _TranscriptionResult(text: text),
          TranscriptionError(:final message) =>
            _TranscriptionErrorDisplay(message: message),
        };
      },
    );
  }
}

/// Displays a transcription error with a retry button.
class _TranscriptionErrorDisplay extends StatelessWidget {
  const _TranscriptionErrorDisplay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              context.read<RecordingCubit>().reset();
              context.read<TranscriptionCubit>().reset();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

/// Shows raw transcription and optional post-processing results.
class _TranscriptionResult extends StatelessWidget {
  const _TranscriptionResult({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostProcessingCubit, PostProcessingState>(
      builder: (context, ppState) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: switch (ppState) {
            PostProcessingIdle() || PostProcessingDisabled() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScrollableText(text: text),
                  const SizedBox(height: 16),
                  const _NewRecordingButton(),
                ],
              ),
            PostProcessingLoading() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raw:', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  _ScrollableText(text: text, fontSize: 14),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Processing...'),
                    ],
                  ),
                ],
              ),
            PostProcessingSuccess(:final processedText) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raw:', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  _ScrollableText(text: text, fontSize: 14),
                  const SizedBox(height: 16),
                  Text(
                    'Processed:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  _ScrollableText(text: processedText),
                  const SizedBox(height: 16),
                  const _NewRecordingButton(),
                ],
              ),
            PostProcessingError(:final message) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScrollableText(text: text),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange,
                          size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<PostProcessingCubit>().process(text);
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Processing'),
                      ),
                      const SizedBox(width: 8),
                      const _NewRecordingButton(),
                    ],
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}

/// A scrollable selectable text widget for long transcriptions.
class _ScrollableText extends StatelessWidget {
  const _ScrollableText({required this.text, this.fontSize = 16});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}

/// Button to reset state and start a new recording.
class _NewRecordingButton extends StatelessWidget {
  const _NewRecordingButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        context.read<RecordingCubit>().reset();
        context.read<TranscriptionCubit>().reset();
        context.read<PostProcessingCubit>().reset();
      },
      icon: const Icon(Icons.mic, size: 16),
      label: const Text('New Recording'),
    );
  }
}
