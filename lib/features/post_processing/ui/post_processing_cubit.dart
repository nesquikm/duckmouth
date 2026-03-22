import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:duckmouth/core/api/llm_client.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_state.dart';

/// Cubit that manages LLM post-processing of transcription results.
class PostProcessingCubit extends Cubit<PostProcessingState> {
  static final _log = Logger('PostProcessingCubit');

  PostProcessingCubit({
    required PostProcessingRepository Function() repositoryFactory,
    required PostProcessingConfig config,
  })  : _repositoryFactory = repositoryFactory,
        _config = config,
        super(const PostProcessingIdle());

  final PostProcessingRepository Function() _repositoryFactory;
  PostProcessingConfig _config;

  /// Update the configuration (e.g. when settings change).
  void updateConfig(PostProcessingConfig config) {
    _config = config;
  }

  /// Process the given [rawText] if post-processing is enabled.
  Future<void> process(String rawText) async {
    // Always transition through Idle first so BlocListener fires even when
    // the previous state was the same (e.g. two consecutive Disabled emits).
    _tryEmit(const PostProcessingIdle());

    if (!_config.enabled) {
      _log.info('Post-processing disabled, passing through raw text');
      _tryEmit(const PostProcessingDisabled());
      return;
    }
    _log.info('Post-processing raw text (${rawText.length} chars)');

    _tryEmit(PostProcessingLoading(rawText: rawText));
    try {
      final processedText =
          await _repositoryFactory().process(rawText, _config.prompt);
      _tryEmit(PostProcessingSuccess(
        rawText: rawText,
        processedText: processedText,
      ));
    } on LlmClientException catch (e, st) {
      _log.warning('LLM API error', e, st);
      _tryEmit(PostProcessingError(
        rawText: rawText,
        message: e.message,
      ));
    } on SocketException catch (e, st) {
      _log.severe('Network error during post-processing', e, st);
      _tryEmit(PostProcessingError(
        rawText: rawText,
        message: 'Network error. Check your internet connection.',
      ));
    } on Exception catch (e, st) {
      _log.severe('Post-processing failed', e, st);
      _tryEmit(PostProcessingError(
        rawText: rawText,
        message: _friendlyError(e),
      ));
    }
  }

  /// Reset to idle state.
  void reset() {
    _tryEmit(const PostProcessingIdle());
  }

  void _tryEmit(PostProcessingState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  static String _friendlyError(Exception e) {
    final message = e.toString();
    if (message.contains('SocketException') ||
        message.contains('Connection refused')) {
      return 'Network error. Check your internet connection.';
    }
    return 'Post-processing failed. Please try again.';
  }
}
