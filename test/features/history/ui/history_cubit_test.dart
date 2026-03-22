import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:duckmouth/features/history/domain/history_repository.dart';
import 'package:duckmouth/features/history/domain/transcription_entry.dart';
import 'package:duckmouth/features/history/ui/history_cubit.dart';
import 'package:duckmouth/features/history/ui/history_state.dart';

class MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  late MockHistoryRepository mockRepo;

  final entry1 = TranscriptionEntry(
    id: '1',
    rawText: 'hello',
    timestamp: DateTime(2026, 3, 22, 10, 0),
  );
  final entry2 = TranscriptionEntry(
    id: '2',
    rawText: 'world',
    processedText: 'World!',
    timestamp: DateTime(2026, 3, 22, 11, 0),
  );

  setUp(() {
    mockRepo = MockHistoryRepository();
  });

  setUpAll(() {
    registerFallbackValue(entry1);
  });

  group('HistoryCubit', () {
    test('initial state is HistoryLoading', () {
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      final cubit = HistoryCubit(repository: mockRepo);
      expect(cubit.state, const HistoryLoading());
      cubit.close();
    });

    blocTest<HistoryCubit, HistoryState>(
      'loadHistory emits [HistoryLoading, HistoryLoaded]',
      setUp: () {
        when(() => mockRepo.getAll()).thenAnswer((_) async => [entry2, entry1]);
      },
      build: () => HistoryCubit(repository: mockRepo),
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const HistoryLoading(),
        HistoryLoaded([entry2, entry1]),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'loadHistory emits HistoryError on failure',
      setUp: () {
        when(() => mockRepo.getAll()).thenThrow(Exception('disk error'));
      },
      build: () => HistoryCubit(repository: mockRepo),
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        const HistoryLoading(),
        const HistoryError('Exception: disk error'),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'addEntry adds and reloads',
      setUp: () {
        when(() => mockRepo.add(any())).thenAnswer((_) async {});
        when(() => mockRepo.getAll()).thenAnswer((_) async => [entry1]);
      },
      build: () => HistoryCubit(repository: mockRepo),
      act: (cubit) => cubit.addEntry(entry1),
      expect: () => [HistoryLoaded([entry1])],
      verify: (_) {
        verify(() => mockRepo.add(entry1)).called(1);
      },
    );

    blocTest<HistoryCubit, HistoryState>(
      'deleteEntry removes and reloads',
      setUp: () {
        when(() => mockRepo.delete(any())).thenAnswer((_) async {});
        when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      },
      build: () => HistoryCubit(repository: mockRepo),
      act: (cubit) => cubit.deleteEntry('1'),
      expect: () => [const HistoryLoaded([])],
      verify: (_) {
        verify(() => mockRepo.delete('1')).called(1);
      },
    );

    blocTest<HistoryCubit, HistoryState>(
      'clearHistory clears and emits empty list',
      setUp: () {
        when(() => mockRepo.clear()).thenAnswer((_) async {});
      },
      build: () => HistoryCubit(repository: mockRepo),
      act: (cubit) => cubit.clearHistory(),
      expect: () => [const HistoryLoaded([])],
      verify: (_) {
        verify(() => mockRepo.clear()).called(1);
      },
    );
  });
}
