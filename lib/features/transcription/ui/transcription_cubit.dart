import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'transcription_state.dart';

/// Cubit that manages speech-to-text transcription state.
class TranscriptionCubit extends Cubit<TranscriptionState> {
  TranscriptionCubit({required SttRepository repository})
      : _repository = repository,
        super(const TranscriptionIdle());

  final SttRepository _repository;

  /// Transcribe the audio file at [audioFilePath].
  Future<void> transcribe(String audioFilePath) async {
    _tryEmit(const TranscriptionLoading());
    try {
      final text = await _repository.transcribe(audioFilePath);
      _tryEmit(TranscriptionSuccess(text));
    } on Exception catch (e) {
      _tryEmit(TranscriptionError(e.toString()));
    }
  }

  void _tryEmit(TranscriptionState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
