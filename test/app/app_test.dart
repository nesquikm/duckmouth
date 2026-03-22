import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/app/app.dart';
import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/transcription/domain/stt_repository.dart';
import 'package:duckmouth/features/transcription/ui/transcription_cubit.dart';

class MockRecordingRepository extends Mock implements RecordingRepository {}

class MockSttRepository extends Mock implements SttRepository {}

void main() {
  late MockRecordingRepository mockRepo;
  late MockSttRepository mockSttRepo;

  setUp(() {
    mockRepo = MockRecordingRepository();
    mockSttRepo = MockSttRepository();
    when(() => mockRepo.dispose()).thenAnswer((_) async {});
    when(() => mockRepo.durationStream)
        .thenAnswer((_) => const Stream<Duration>.empty());

    final sl = GetIt.instance;
    sl.registerFactory<RecordingCubit>(
      () => RecordingCubit(repository: mockRepo),
    );
    sl.registerFactory<TranscriptionCubit>(
      () => TranscriptionCubit(repository: mockSttRepo),
    );
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets('DuckmouthApp renders without error', (tester) async {
    await tester.pumpWidget(const DuckmouthApp());
    expect(find.text('Duckmouth'), findsOneWidget);
    expect(find.text('Ready to record'), findsOneWidget);
  });
}
