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

integration_test/
├── app_test.dart          # E2E test scenarios (happy path, errors, retry)
├── settings_test.dart     # Settings round-trip E2E
├── history_test.dart      # History CRUD E2E
└── helpers/
    ├── test_harness.dart  # GetIt overrides with fakes, app bootstrapping
    └── fakes/             # Fake implementations of service interfaces
        ├── fake_recording_repository.dart
        ├── fake_stt_repository.dart
        ├── fake_post_processing_repository.dart
        ├── fake_sound_service.dart
        ├── fake_accessibility_service.dart
        ├── fake_clipboard_service.dart
        └── fake_hotkey_service.dart
```

## 3. Conventions

### Naming
- Files: `*_test.dart`
- Test names: describe expected behavior (`'emits [recording] when start is called'`)

### When to Update Tests
- **Every code change must include corresponding test updates.** New features need new tests, modified behavior needs updated assertions, removed code needs pruned tests.
- Integration/E2E tests must be updated when user-facing flows change (new UI, new settings fields, new error paths).
- The gate (`fvm flutter analyze && fvm flutter test`) enforces this — no merge without green tests.

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

## 9. Hotkey Recorder & Key Code Translation Tests

### Key code translator
- USB HID `0x0007002C` (Space) maps to Carbon `49`
- USB HID `0x00070004` (A) maps to Carbon `0`
- All letter/number/function/special keys have correct Carbon mappings
- Unknown USB HID code returns `null`
- `usbHidToLabel` returns human-readable names ("Space", "A", "F1", etc.)
- `usbHidToLabel` for unknown code returns formatted hex fallback

### Custom hotkey recorder dialog
- Pressing bare modifier (e.g., Control alone) does NOT fire `onHotKeyRecorded`
- Pressing modifier+key combo (e.g., Ctrl+Space) fires with correct config
- Multiple modifiers work (e.g., Ctrl+Shift+Space)
- Display updates live as modifiers are pressed ("Ctrl + ...")
- Releasing all keys without a non-modifier key resets the state
- Escape key cancels recording

### Hotkey display in settings
- Default hotkey shows "Ctrl + Shift + Space" (not hex codes)
- Custom hotkey combo displays all modifier names + key label
- Recorded hotkey round-trips: record → save → reload → display matches

### Hotkey registration (native)
- HotkeyConfig with USB HID code is translated to Carbon before native registration
- Invalid key codes are handled gracefully (error state, not crash)

## 10. End-to-End Integration Tests

### Overview
Full-app integration tests using `IntegrationTestWidgetsFlutterBinding` that launch the real app with fake backends. All fakes implement production interfaces — no HTTP calls, no platform channels.

### Test Harness
- Uses `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
- Overrides GetIt registrations with fakes before `pumpWidget(DuckmouthApp())`
- `SharedPreferences.setMockInitialValues()` for deterministic settings
- `tester.runAsync()` for tap operations that trigger async cubit flows

### Fake Services
All fakes implement existing abstract interfaces (type-safe, no `when()` setup):

| Fake | Behavior |
|------|----------|
| `FakeRecordingRepository` | Simulates mic capture; returns a canned audio file path after configurable delay |
| `FakeSttRepository` | Returns canned transcription text; can be configured to throw for error scenarios |
| `FakePostProcessingRepository` | Returns canned processed text; can be configured to throw or disabled |
| `FakeSoundService` | No-op; records calls for assertion |
| `FakeAccessibilityService` | No-op; returns granted permission status |
| `FakeClipboardService` | Captures output text in a buffer for assertion |
| `FakeHotkeyService` | No-op; no native hotkey registration |

### E2E Scenarios

#### Happy path
1. App launches → home page visible
2. Tap record → recording state shown
3. Recording completes → transcription loading shown
4. Transcription succeeds → raw text displayed
5. Post-processing succeeds → processed text displayed
6. Result copied/pasted → verify via FakeClipboardService
7. History entry created → navigate to history → verify entry

#### STT error & retry
1. Configure FakeSttRepository to throw on first call
2. Record → transcription fails → error message shown
3. Tap retry → FakeSttRepository succeeds → transcription displayed

#### Post-processing error & retry
1. Configure FakePostProcessingRepository to throw on first call
2. Record → transcribe → post-processing fails → error shown with raw text
3. Tap retry → post-processing succeeds → processed text displayed

#### Post-processing disabled
1. Configure settings with post-processing disabled
2. Record → transcribe → post-processing skipped
3. Raw text displayed and copied directly

#### Settings round-trip
1. Navigate to settings
2. Change STT config (endpoint, model)
3. Save → navigate back → reopen settings
4. Verify config persisted

#### Model discovery in settings
1. Navigate to settings with a configured provider (FakeModelsClient returns model list)
2. STT model dropdown shows filtered STT models
3. LLM model dropdown shows filtered LLM models
4. Change provider base URL → model list refreshes
5. FakeModelsClient returns error → dropdown falls back to free-text field

#### History CRUD
1. Complete a transcription
2. Navigate to history → verify entry with timestamp
3. Swipe to delete → verify removal
4. Complete another transcription → clear all → verify empty

### Running
```bash
fvm flutter test integration_test/
```

## 11. Structured Logging Tests

### Logging setup (`test/core/logging/logging_setup_test.dart`)
- `setupLogging()` initializes TheLogger with `dbLogger: false` and `consoleLogger: true`
- Session start message includes app version string
- Calling `setupLogging()` twice does not crash (idempotent — disposes first if needed)

### Masking
- API key added via `addMaskingString` is redacted in log output
- Removing/changing an API key updates masking strings (old key removed, new key added)
- Empty API key string is not added as a masking string

### Logger instances in services
- Key services (recording repo, STT repo, post-processing repo, clipboard service, sound service, hotkey cubit, settings cubit) have Logger instances with correct names
- Errors logged with `Logger.severe()` include the error object and stack trace
- No remaining `print()` or `debugPrint()` calls in `lib/` (verified by grep, not test)

## 12. Dynamic Model Discovery Tests

### ModelsClient (`test/core/api/models_client_test.dart`)
- Fetches and parses `/v1/models` response correctly
- Returns empty list on HTTP error (4xx, 5xx)
- Returns empty list on network/timeout error
- Handles malformed JSON gracefully

### Model filtering (`test/core/api/model_filter_test.dart`)
- Filters STT models: includes `whisper-1`, `whisper-large-v3-turbo`, excludes `gpt-4o`
- Filters LLM models: includes `gpt-4o`, `llama-3`, excludes `whisper-1`, `text-embedding-*`, `tts-*`, `dall-e-*`
- Case-insensitive matching

### Model dropdown widget (`test/features/settings/ui/model_dropdown_test.dart`)
- Shows loading indicator while fetching
- Shows dropdown with fetched models on success
- Falls back to text field on fetch failure
- Refreshes when base URL changes
- Refreshes when API key changes
- Selected model preserved if still in list after refresh
- Free-text fallback allows typing arbitrary model name
