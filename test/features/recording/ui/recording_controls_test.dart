import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/features/recording/domain/recording_repository.dart';
import 'package:duckmouth/features/recording/ui/recording_controls.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';
import 'package:duckmouth/features/recording/ui/recording_state.dart';

class MockRecordingRepository extends Mock implements RecordingRepository {}

void main() {
  late MockRecordingRepository mockRepo;
  late RecordingCubit cubit;

  setUp(() {
    mockRepo = MockRecordingRepository();
    when(() => mockRepo.dispose()).thenAnswer((_) async {});
    when(() => mockRepo.durationStream)
        .thenAnswer((_) => const Stream<Duration>.empty());
    cubit = RecordingCubit(repository: mockRepo);
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<RecordingCubit>.value(
          value: cubit,
          child: const RecordingControls(),
        ),
      ),
    );
  }

  testWidgets('shows Ready to record and mic icon in idle state',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Ready to record'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.text('00:00.0'), findsOneWidget);
  });

  testWidgets('shows Recording... and stop icon when recording',
      (tester) async {
    when(() => mockRepo.hasPermission()).thenAnswer((_) async => true);
    when(() => mockRepo.start()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await cubit.startRecording();
    await tester.pump();

    expect(find.text('Recording...'), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);
  });

  testWidgets('shows Recording saved when recording completes',
      (tester) async {
    when(() => mockRepo.stop()).thenAnswer((_) async => '/tmp/test.m4a');

    await tester.pumpWidget(buildTestWidget());
    await cubit.stopRecording();
    await tester.pump();

    expect(find.text('Recording saved'), findsOneWidget);
  });

  testWidgets('shows error message on error', (tester) async {
    when(() => mockRepo.hasPermission()).thenAnswer((_) async => false);
    when(() => mockRepo.requestPermission()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await cubit.startRecording();
    await tester.pump();

    expect(find.textContaining('Microphone access required'), findsOneWidget);
  });

  testWidgets('tapping mic button calls startRecording', (tester) async {
    when(() => mockRepo.hasPermission()).thenAnswer((_) async => true);
    when(() => mockRepo.start()).thenAnswer((_) async {});

    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.byIcon(Icons.mic));
    await tester.pump();

    verify(() => mockRepo.start()).called(1);
  });

  testWidgets('tapping stop button calls stopRecording', (tester) async {
    // Put cubit in recording state directly
    when(() => mockRepo.stop()).thenAnswer((_) async => '/tmp/test.m4a');

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    cubit.emit(const RecordingInProgress(Duration(seconds: 5)));

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Verify the stop icon is shown
    expect(find.byIcon(Icons.stop), findsOneWidget);

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();

    verify(() => mockRepo.stop()).called(1);
  });

  testWidgets('displays formatted duration when recording', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    // Directly emit a RecordingInProgress state with a specific duration
    cubit.emit(
      const RecordingInProgress(
        Duration(minutes: 1, seconds: 23, milliseconds: 400),
      ),
    );
    await tester.pump();

    expect(find.text('01:23.4'), findsOneWidget);
  });
}
