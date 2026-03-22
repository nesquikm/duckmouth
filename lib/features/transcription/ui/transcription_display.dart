import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/features/post_processing/ui/post_processing_cubit.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_state.dart';
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
          TranscriptionSuccess(:final text) => _TranscriptionResult(text: text),
          TranscriptionError(:final message) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
            ),
        };
      },
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
            PostProcessingIdle() || PostProcessingDisabled() =>
              SelectableText(text, style: const TextStyle(fontSize: 16)),
            PostProcessingLoading() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raw:', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  SelectableText(text, style: const TextStyle(fontSize: 16)),
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
                  SelectableText(text, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  Text(
                    'Processed:',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    processedText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            PostProcessingError(:final message) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(text, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Text(
                    'Post-processing error: $message',
                    style: const TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                ],
              ),
          },
        );
      },
    );
  }
}
