# Testing Specification

## 1. Test Framework

- **Runner:** flutter_test (`fvm flutter test`)
- **Mocking:** mocktail (NOT mockito)
- **BLoC testing:** bloc_test
- **Coverage:** `fvm flutter test --coverage` (lcov)

## 2. Test Structure

```
test/
├── features/
│   ├── recording/
│   │   ├── data/
│   │   ├── domain/
│   │   └── ui/
│   ├── transcription/
│   │   ├── data/
│   │   ├── domain/
│   │   └── ui/
│   ├── history/
│   ├── settings/
│   ├── hotkeys/
│   ├── menubar/
│   └── output/
├── core/
│   └── api/
└── helpers/              # Shared test utilities, fakes, fixtures
```

## 3. Conventions

### Naming
- Files: `*_test.dart`
- Test names: describe expected behavior (`'emits [recording] when start is called'`)

### What to Test
- Cubit state transitions (using bloc_test `blocTest()`)
- Repository methods with mocked data sources
- Model serialization/deserialization
- API client request/response handling with mocked HTTP
- Widget rendering and interaction for key UI components
- Error paths and edge cases

### What NOT to Test
- Flutter framework internals
- Generated code (`*.g.dart`, `*.freezed.dart`)
- Platform channel internals (trust the plugin)
- Exact pixel layouts

### Mocking Patterns
```dart
// Register mocks
class MockSttRepository extends Mock implements SttRepository {}

// Use in tests
late MockSttRepository mockRepo;
setUp(() {
  mockRepo = MockSttRepository();
});
```

### BLoC Testing Pattern
```dart
blocTest<TranscriptionCubit, TranscriptionState>(
  'emits [loading, success] when transcribe succeeds',
  build: () {
    when(() => mockRepo.transcribe(any())).thenAnswer(
      (_) async => 'Hello world',
    );
    return TranscriptionCubit(repository: mockRepo);
  },
  act: (cubit) => cubit.transcribe(audioData),
  expect: () => [
    TranscriptionState.loading(),
    TranscriptionState.success('Hello world'),
  ],
);
```

## 4. Coverage Targets

| Layer | Target | Minimum |
|-------|--------|---------|
| Cubits/BLoCs | >=90% | 80% |
| Repositories | >=90% | 80% |
| Models/Domain | >=95% | 90% |
| UI/Widgets | >=60% | 40% |
| Overall | >=75% | 65% |

## 5. Test Data

- Use factory functions in `test/helpers/` for creating test models
- Frozen timestamps: `DateTime(2026, 1, 1)` for deterministic tests
- Mock API responses as JSON strings in test fixtures
- No real network calls — all HTTP mocked via mocktail
