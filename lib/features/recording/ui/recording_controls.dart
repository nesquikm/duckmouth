import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'recording_cubit.dart';
import 'recording_state.dart';

/// Widget that displays recording controls (start/stop button and duration).
class RecordingControls extends StatelessWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingCubit, RecordingState>(
      builder: (context, state) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusText(state),
            const SizedBox(height: 24),
            _buildDurationDisplay(state),
            const SizedBox(height: 32),
            _buildRecordButton(context, state),
          ],
        );
      },
    );
  }

  Widget _buildStatusText(RecordingState state) {
    final String text;
    final Color color;

    switch (state) {
      case RecordingIdle():
        text = 'Ready to record';
        color = Colors.grey;
      case RecordingInProgress():
        text = 'Recording...';
        color = Colors.red;
      case RecordingComplete():
        text = 'Recording saved';
        color = Colors.green;
      case RecordingError(:final message):
        text = message;
        color = Colors.red;
    }

    return Text(
      text,
      style: TextStyle(fontSize: 16, color: color),
    );
  }

  Widget _buildDurationDisplay(RecordingState state) {
    final duration = switch (state) {
      RecordingInProgress(:final duration) => duration,
      _ => Duration.zero,
    };

    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths =
        (duration.inMilliseconds.remainder(1000) ~/ 100).toString();

    return Text(
      '$minutes:$seconds.$tenths',
      style: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context, RecordingState state) {
    final isRecording = state is RecordingInProgress;
    final cubit = context.read<RecordingCubit>();

    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton(
        onPressed: isRecording ? cubit.stopRecording : cubit.startRecording,
        backgroundColor: isRecording ? Colors.red : null,
        child: Icon(
          isRecording ? Icons.stop : Icons.mic,
          size: 32,
        ),
      ),
    );
  }
}
