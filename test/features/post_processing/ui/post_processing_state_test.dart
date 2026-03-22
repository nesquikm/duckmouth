import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/post_processing/ui/post_processing_state.dart';

void main() {
  group('PostProcessingState', () {
    test('PostProcessingIdle equality', () {
      expect(const PostProcessingIdle(), const PostProcessingIdle());
    });

    test('PostProcessingDisabled equality', () {
      expect(const PostProcessingDisabled(), const PostProcessingDisabled());
    });

    test('PostProcessingLoading equality', () {
      expect(
        const PostProcessingLoading(rawText: 'a'),
        const PostProcessingLoading(rawText: 'a'),
      );
      expect(
        const PostProcessingLoading(rawText: 'a'),
        isNot(const PostProcessingLoading(rawText: 'b')),
      );
    });

    test('PostProcessingSuccess equality', () {
      expect(
        const PostProcessingSuccess(rawText: 'a', processedText: 'b'),
        const PostProcessingSuccess(rawText: 'a', processedText: 'b'),
      );
      expect(
        const PostProcessingSuccess(rawText: 'a', processedText: 'b'),
        isNot(const PostProcessingSuccess(rawText: 'a', processedText: 'c')),
      );
    });

    test('PostProcessingError equality', () {
      expect(
        const PostProcessingError(rawText: 'a', message: 'err'),
        const PostProcessingError(rawText: 'a', message: 'err'),
      );
      expect(
        const PostProcessingError(rawText: 'a', message: 'err'),
        isNot(const PostProcessingError(rawText: 'a', message: 'other')),
      );
    });
  });
}
