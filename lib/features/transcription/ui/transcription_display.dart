import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'transcription_cubit.dart';
import 'transcription_state.dart';

/// Widget that displays the transcription result.
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
          TranscriptionSuccess(:final text) => Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
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
