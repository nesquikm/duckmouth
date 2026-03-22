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
- Audio format configuration and encoder wiring
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

## 6. Audio Format Tests

### AudioFormatConfig model
- Default config produces WAV 16kHz 16-bit mono
- Each quality preset maps to correct format/sampleRate/bitRate values
- Custom format overrides preset defaults

### Recording repository encoder wiring
- Mock `record` plugin; verify encoder is configured with correct format per AudioFormatConfig
- WAV preset → RecordConfig with wav encoder, 16kHz, mono
- Balanced preset → RecordConfig with AAC encoder, 64kbps, 16kHz, mono
- Smallest preset → RecordConfig with AAC encoder, 32kbps, 16kHz, mono
- Format change in settings is picked up by next recording

### Settings cubit
- Changing quality preset updates AudioFormatConfig in state
- Changing individual format fields switches preset to "custom"
- Settings persist and restore AudioFormatConfig correctly

### STT API client
- Multipart upload sets correct MIME type for each format (audio/wav, audio/flac, audio/mp4, audio/ogg)

## 7. Native Sound Playback Tests

### SoundService (platform channel)
- Mock MethodChannel returns success for valid sound names
- Mock MethodChannel returns error for unknown sound names
- Volume is clamped to 0.0–1.0 before passing to platform channel
- Channel unavailable (e.g., non-macOS platform) fails gracefully without crash
- Each sound event (start, stop, complete) maps to correct system sound name

### Integration with existing sound settings
- Sound enable/disable toggle still prevents/allows playback
- Per-sound volume values passed correctly through the channel
- SoundConfig persistence unchanged from M8

## 8. Accessibility & Text Insertion Tests

### AccessibilityService (platform channel)
- Mock MethodChannel returns permission status correctly for each case (granted, denied, unknown)
- `insertTextViaAccessibility` calls platform channel with correct arguments
- `pasteViaCGEvent` calls platform channel with correct arguments
- `requestAccessibilityPermission` invokes the correct platform method

### Fallback chain
- When AX insert succeeds, CGEvent and osascript are NOT called
- When AX insert fails, falls back to CGEvent
- When CGEvent fails, falls back to osascript
- All three fail → error propagated to caller

### Permission UI
- Banner/dialog shown when permission is denied
- Banner hidden when permission is granted
- Settings page shows current permission status
- "Open System Settings" button calls requestAccessibilityPermission

### ClipboardService integration
- `pasteAtCursor` delegates to AccessibilityService when available
- Clipboard contents unchanged after successful AX direct insert
- Clipboard restored after CGEvent/osascript fallback
