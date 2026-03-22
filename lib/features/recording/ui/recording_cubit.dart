import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/recording_repository_impl.dart';
import '../domain/recording_repository.dart';
import 'recording_state.dart';

/// Cubit that manages audio recording state.
class RecordingCubit extends Cubit<RecordingState> {
  RecordingCubit({required RecordingRepository repository})
      : _repository = repository,
        super(const RecordingIdle());

  final RecordingRepository _repository;
  StreamSubscription<Duration>? _durationSubscription;

  /// Start recording audio from the microphone.
  Future<void> startRecording() async {
    try {
      final hasPermission = await _repository.hasPermission();
      if (!hasPermission) {
        await _repository.requestPermission();
        final granted = await _repository.hasPermission();
        if (!granted) {
          _tryEmit(const RecordingError(
            'Microphone access required. Open System Settings > '
            'Privacy & Security > Microphone and enable access '
            'for Duckmouth.',
          ));
          return;
        }
      }

      await _repository.start();
      _tryEmit(const RecordingInProgress(Duration.zero));

      _durationSubscription?.cancel();
      _durationSubscription = _repository.durationStream.listen(
        (duration) => _tryEmit(RecordingInProgress(duration)),
      );
    } on RecordingPermissionException catch (e) {
      _tryEmit(RecordingError(e.message));
    } on Exception catch (e) {
      _tryEmit(RecordingError('Failed to start recording: $e'));
    }
  }

  /// Stop the current recording.
  Future<void> stopRecording() async {
    try {
      await _durationSubscription?.cancel();
      _durationSubscription = null;

      final filePath = await _repository.stop();
      if (filePath != null) {
        _tryEmit(RecordingComplete(filePath));
      } else {
        _tryEmit(const RecordingError('No recording data available'));
      }
    } on Exception catch (e) {
      _tryEmit(RecordingError('Failed to stop recording: $e'));
    }
  }

  /// Reset to idle state for a new recording.
  void reset() {
    _tryEmit(const RecordingIdle());
  }

  void _tryEmit(RecordingState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  @override
  Future<void> close() async {
    await _durationSubscription?.cancel();
    await _repository.dispose();
    return super.close();
  }
}
