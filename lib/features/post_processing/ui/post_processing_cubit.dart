import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/features/post_processing/domain/post_processing_config.dart';
import 'package:duckmouth/features/post_processing/domain/post_processing_repository.dart';
import 'package:duckmouth/features/post_processing/ui/post_processing_state.dart';

/// Cubit that manages LLM post-processing of transcription results.
class PostProcessingCubit extends Cubit<PostProcessingState> {
  PostProcessingCubit({
    required PostProcessingRepository repository,
    required PostProcessingConfig config,
  })  : _repository = repository,
        _config = config,
        super(const PostProcessingIdle());

  final PostProcessingRepository _repository;
  PostProcessingConfig _config;

  /// Update the configuration (e.g. when settings change).
  void updateConfig(PostProcessingConfig config) {
    _config = config;
  }

  /// Process the given [rawText] if post-processing is enabled.
  Future<void> process(String rawText) async {
    if (!_config.enabled) {
      _tryEmit(const PostProcessingDisabled());
      return;
    }

    _tryEmit(PostProcessingLoading(rawText: rawText));
    try {
      final processedText = await _repository.process(rawText, _config.prompt);
      _tryEmit(PostProcessingSuccess(
        rawText: rawText,
        processedText: processedText,
      ));
    } on Exception catch (e) {
      _tryEmit(PostProcessingError(
        rawText: rawText,
        message: e.toString(),
      ));
    }
  }

  void _tryEmit(PostProcessingState state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
