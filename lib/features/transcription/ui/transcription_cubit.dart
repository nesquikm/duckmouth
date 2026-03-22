import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:duckmouth/core/api/openai_client.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'transcription_state.dart';

/// Cubit that manages speech-to-text transcription state.
class TranscriptionCubit extends Cubit<TranscriptionState> {
  static final _log = Logger('TranscriptionCubit');

  TranscriptionCubit({required SttRepository Function() repositoryFactory})
      : _repositoryFactory = repositoryFactory,
        super(const TranscriptionIdle());

  final SttRepository Function() _repositoryFactory;

  /// Transcribe the audio file at [audioFilePath].
  Future<void> transcribe(String audioFilePath) async {
    _tryEmit(const TranscriptionLoading());
    try {
      final text = await _repositoryFactory().transcribe(audioFilePath);
      if (text.trim().isEmpty) {
        _tryEmit(const TranscriptionError(
          'No speech detected. Try speaking louder or check your microphone.',
        ));
        return;
      }
      _tryEmit(TranscriptionSuccess(text));
    } on OpenAiClientException catch (e, st) {
      _log.warning('STT API error', e, st);
      _tryEmit(TranscriptionError(e.message));
    } on SocketException catch (e, st) {
      _log.severe('Network error during transcription', e, st);
      _tryEmit(const TranscriptionError(
        'Network error. Check your internet connection and try again.',
      ));
    } on HttpException catch (e, st) {
      _log.severe('HTTP error during transcription', e, st);
      _tryEmit(const TranscriptionError(
        'Network error. Check your internet connection and try again.',
      ));
    } on Exception catch (e, st) {
      _log.severe('Transcription failed', e, st);
      _tryEmit(TranscriptionError(_friendlyError(e)));
    }
  }

  /// Reset the cubit to idle state for a new recording.
  void reset() {
    _tryEmit(const TranscriptionIdle());
  }

  void _tryEmit(TranscriptionState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  static String _friendlyError(Exception e) {
    final message = e.toString();
    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Network is unreachable')) {
      return 'Network error. Check your internet connection and try again.';
    }
    return 'Transcription failed. Please try again.';
  }
}
