import 'package:flutter_test/flutter_test.dart';
import 'package:duckmouth/features/recording/ui/recording_state.dart';

void main() {
  group('RecordingState', () {
    test('RecordingIdle supports value equality', () {
      expect(const RecordingIdle(), equals(const RecordingIdle()));
    });

    test('RecordingInProgress supports value equality', () {
      expect(
        const RecordingInProgress(Duration(seconds: 5)),
        equals(const RecordingInProgress(Duration(seconds: 5))),
      );
      expect(
        const RecordingInProgress(Duration(seconds: 5)),
        isNot(equals(const RecordingInProgress(Duration(seconds: 10)))),
      );
    });

    test('RecordingComplete supports value equality', () {
      expect(
        const RecordingComplete('/tmp/a.m4a'),
        equals(const RecordingComplete('/tmp/a.m4a')),
      );
      expect(
        const RecordingComplete('/tmp/a.m4a'),
        isNot(equals(const RecordingComplete('/tmp/b.m4a'))),
      );
    });

    test('RecordingError supports value equality', () {
      expect(
        const RecordingError('fail'),
        equals(const RecordingError('fail')),
      );
      expect(
        const RecordingError('fail'),
        isNot(equals(const RecordingError('other'))),
      );
    });

    test('different state types are not equal', () {
      expect(
        const RecordingIdle(),
        isNot(equals(const RecordingInProgress(Duration.zero))),
      );
    });
  });
}
