import 'package:flutter_test/flutter_test.dart';

import 'package:duckmouth/features/transcription/ui/transcription_state.dart';

void main() {
  group('TranscriptionState', () {
    test('TranscriptionIdle equals another TranscriptionIdle', () {
      expect(const TranscriptionIdle(), const TranscriptionIdle());
    });

    test('TranscriptionLoading equals another TranscriptionLoading', () {
      expect(const TranscriptionLoading(), const TranscriptionLoading());
    });

    test('TranscriptionSuccess with same text are equal', () {
      expect(
        const TranscriptionSuccess('hi'),
        const TranscriptionSuccess('hi'),
      );
    });

    test('TranscriptionSuccess with different text are not equal', () {
      expect(
        const TranscriptionSuccess('hi'),
        isNot(const TranscriptionSuccess('bye')),
      );
    });

    test('TranscriptionError with same message are equal', () {
      expect(
        const TranscriptionError('fail'),
        const TranscriptionError('fail'),
      );
    });

    test('TranscriptionError with different message are not equal', () {
      expect(
        const TranscriptionError('a'),
        isNot(const TranscriptionError('b')),
      );
    });

    test('different state types are not equal', () {
      expect(const TranscriptionIdle(), isNot(const TranscriptionLoading()));
      expect(
        const TranscriptionSuccess('hi'),
        isNot(const TranscriptionError('hi')),
      );
    });
  });
}
