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
2. Change STT config (endpoint, model) — auto-saved
3. Navigate back → reopen settings
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
- Fetches and parses `/models` response correctly (note: no `/v1/` prefix — base URL includes version path)
- Returns `FetchModelsSuccess` with model list on 200 OK
- Returns `FetchModelsFailure` with "Unauthorized — check API key" on HTTP 401
- Returns `FetchModelsFailure` with "Access denied — check API key permissions" on HTTP 403
- Returns `FetchModelsFailure` with "Not found — check endpoint URL" on HTTP 404
- Returns `FetchModelsFailure` with "Rate limited — try again later" on HTTP 429
- Returns `FetchModelsFailure` with "Server error (500)" on HTTP 5xx
- Returns `FetchModelsFailure` with "Network error — check connection" on network/timeout
- Returns `FetchModelsFailure` with "Unexpected response format" on malformed JSON
- Empty baseUrl or apiKey: returns empty success (no fetch attempted)

### Model filtering (`test/core/api/model_filter_test.dart`)
- Filters STT models: includes `whisper-1`, `whisper-large-v3-turbo`, excludes `gpt-4o`
- Filters LLM models: includes `gpt-4o`, `llama-3`, `grok-4-1-fast-non-reasoning`, `gemini-3-flash`, excludes `whisper-1`, `text-embedding-*`, `tts-*`, `dall-e-*`
- Case-insensitive matching

### Model dropdown widget (`test/features/settings/ui/model_dropdown_test.dart`)
- Shows loading indicator (spinner suffix) while fetching
- Always renders a TextField (autocomplete combo-box, not locked dropdown)
- Shows autocomplete suggestions from fetched models on success
- Shows specific error reason in helper text on failure (e.g. "401 Unauthorized — check API key")
- Shows "This provider has no STT models" hint when provider default STT model is empty
- Refreshes when base URL changes
- Refreshes when API key changes
- Current model text preserved after fetch
- Free-text typing always works (even after successful fetch)
- Disabled field does not accept input

## 13. DMG Distribution Tests

### Build script (`scripts/build_dmg.sh`)
- Script is executable and runs without errors on a clean checkout
- Produces a `.dmg` file in `build/dmg/`
- DMG filename includes version from `pubspec.yaml`
- `.app` bundle inside DMG is ad-hoc signed (verify with `codesign -v`)
- DMG mounts and contains the app + Applications symlink

### Homebrew cask formula
- `brew audit --cask duckmouth` passes (syntax, required fields)
- Formula version matches latest GitHub Release tag
- SHA256 in formula matches the published DMG
- `postflight` block present and strips quarantine attribute (`xattr -dr com.apple.quarantine`)
- `zap` stanza lists correct app data paths
- After `brew install`, app launches without Gatekeeper prompt (quarantine stripped by postflight)
- After `brew upgrade`, app still launches (postflight re-strips quarantine on each install)
- `brew uninstall --zap` removes app data directories

**Note:** These are manual verification steps and shell-based checks, not Dart unit tests. The gate check (`fvm flutter analyze && fvm flutter test`) still applies to any Dart code changes but the distribution pipeline itself is verified manually or via CI.

## 14. Model Selection Fix Tests

### ProviderPreset (`test/features/settings/domain/provider_preset_test.dart`)
- Each preset has correct `llmModel` value (openAi → `gpt-5.4-mini`, groq → `llama-3.3-70b-versatile`, xAi → `grok-4-1-fast-non-reasoning`, googleGemini → `gemini-3-flash`, openRouter → `openrouter/auto`, custom → empty)
- `toApiConfig` still uses `model` (STT) by default

### Settings page model integration
- PP preset change sets `llmModel` (not `model`) in PP model controller
- STT model field enabled for all presets (not just custom)
- PP model field enabled when post-processing is enabled (not just custom)

## 15. Auto-Save Settings Tests

### Settings page behavior
- Save button absent from UI
- Changing a dropdown/switch calls the corresponding cubit save method immediately
- Text field changes trigger debounced save after 500ms
- `didUpdateWidget` does not overwrite controller when text matches (loop prevention)

### Settings cubit
- All existing `save*()` methods work correctly (no changes needed — already tested)

## 16. Volume Preview Sound Tests

### `_VolumeSlider` behavior
- Releasing a slider triggers `onChangeEnd` callback
- Start volume slider plays `playRecordingStart` at selected volume
- Stop volume slider plays `playRecordingStop` at selected volume
- Complete volume slider plays `playTranscriptionComplete` at selected volume
- Sound config saved on slider release

## 17. Dark Mode Banner Colors Tests

### `_AccessibilityPermissionBanner` (settings page)
- Granted state: light green background in light mode, dark green in dark mode
- Denied state: light orange background in light mode, dark orange in dark mode
- Icon colors differ between light and dark modes

### `_AccessibilityBanner` (home page)
- Orange warning banner uses dark-appropriate colors in dark mode

## 18. Base URL Path Migration Tests

### API client URL construction
- `OpenAiClientImpl` constructs `$baseUrl/audio/transcriptions` (no `/v1/` inserted)
- `LlmClientImpl` constructs `$baseUrl/chat/completions` (no `/v1/` inserted)
- `ModelsClientImpl` constructs `$baseUrl/models` (no `/v1/` inserted)
- All existing API tests pass with updated base URLs (e.g. `https://api.openai.com/v1`)

### Provider preset base URLs
- OpenAI preset baseUrl is `https://api.openai.com/v1`
- Groq preset baseUrl is `https://api.groq.com/openai/v1`
- xAI preset baseUrl is `https://api.x.ai/v1`
- Google Gemini preset baseUrl is `https://generativelanguage.googleapis.com/v1beta/openai`
- OpenRouter preset baseUrl is `https://openrouter.ai/api/v1`

### Settings migration (`test/features/settings/data/settings_repository_impl_test.dart`)
- Saved `https://api.openai.com` migrated to `https://api.openai.com/v1` on load
- Saved `https://api.groq.com/openai` migrated to `https://api.groq.com/openai/v1` on load
- Already-migrated URL (e.g. `https://api.openai.com/v1`) is not double-appended
- Custom URLs (e.g. `http://localhost:11434/v1`) are not modified
- Migration applies to both STT and PP base URLs

## 19. Additional Provider Presets Tests

### ProviderPreset (`test/features/settings/domain/provider_preset_test.dart`)
- xAI preset: label "xAI (Grok)", baseUrl `https://api.x.ai/v1`, model `""`, llmModel `grok-4-1-fast-non-reasoning`
- Google Gemini preset: label "Google Gemini", baseUrl `https://generativelanguage.googleapis.com/v1beta/openai`, model `""`, llmModel `gemini-3-flash`
- OpenRouter preset: label "OpenRouter", baseUrl `https://openrouter.ai/api/v1`, model `""`, llmModel `openrouter/auto`
- `fromName` resolves `xAi`, `googleGemini`, `openRouter` correctly
- `toApiConfig` works for all new presets

### Settings UI
- Provider dropdown shows 6 options (OpenAI, Groq, xAI, Google Gemini, OpenRouter, Custom) in STT section
- Provider dropdown shows 6 options in PP section
- Selecting xAI for STT shows "This provider has no STT models" hint
- Selecting Google Gemini for STT shows "This provider has no STT models" hint
- Selecting OpenRouter for STT shows "This provider has no STT models" hint

## 20. In-App Log Viewer Tests

### Dependency upgrade
- `fvm flutter pub get` succeeds with `the_logger: ^0.0.20` and `the_logger_viewer_widget: ^0.0.2` from pub.dev
- No path dependencies remain for `the_logger`
- Existing logging setup tests still pass after upgrade

### Navigation (`test/app/home_page_test.dart`)
- Home AppBar contains a "Logs" icon button (`Icons.bug_report`)
- Tapping "Logs" button pushes a route containing `TheLoggerViewerPage`
- Log viewer page has an AppBar with title "Log Viewer"
- Back navigation returns to home page

### Widget integration
- `TheLoggerViewerWidget` renders without error when `TheLogger` is initialized
- No custom cubit tests needed — widget manages its own state (tested by the package)

### Existing test compatibility
- All `test/core/logging/logging_setup_test.dart` tests pass with `the_logger` 0.0.20
- Masking tests still work
- Session start logging still works

## 21. Hotkey Rapid Press Race Condition Tests

### RecordingCubit (`test/features/recording/ui/recording_cubit_test.dart`)
- `stopRecording()` called while `startRecording()` is in progress sets `_pendingStop` and does not call `_repository.stop()`
- After `startRecording()` completes with `_pendingStop = true`, `stopRecording()` is auto-called
- Final state after rapid press/release is `RecordingComplete` or `RecordingIdle` (not stuck in `RecordingInProgress`)
- Normal start/stop flow is unaffected (no regression)
- Toggle mode: rapid double-tap stops cleanly
- `_pendingStop` is reset on new `startRecording()` call

## 22. Theme Selection Tests

### SettingsCubit
- Default `themeMode` is `AppThemeMode.system`
- Changing theme mode emits updated state with new mode
- Theme mode persisted to SharedPreferences on change
- Theme mode loaded from SharedPreferences on `loadSettings()`

### Settings page
- Theme mode dropdown shows three options: System, Dark, Light
- Selecting a theme triggers immediate save (auto-save pattern)

### App widget (`test/app/app_test.dart`)
- `MaterialApp` uses `ThemeMode.system` by default
- `MaterialApp` uses `ThemeMode.dark` when cubit state is dark
- `MaterialApp` uses `ThemeMode.light` when cubit state is light

## 23. Branded Color Scheme Tests

### AppTheme unit tests (`test/core/theme/app_theme_test.dart`)
- Light theme seed color is `Color(0xFFE8A838)`
- Dark theme seed color is `Color(0xFFE8A838)`
- Both themes have `useMaterial3: true`
- Light theme has `Brightness.light`
- Dark theme has `Brightness.dark`

## 24. Tray Icon Click Handler Tests

### SystemTrayManager (`test/app/system_tray_manager_test.dart`)
- Left-click event triggers the `onShow` callback
- Right-click event does not trigger `onShow` (menu handles it)
- Rapid double-click only triggers `onShow` once (debounce guard)
- `onShow` callback not called if not registered

## 25. Tray Icon Recording Indicator Tests

### SystemTrayManager (`test/app/system_tray_manager_test.dart`)
- `setRecording(true)` calls `setImage` with `tray_icon_recording.png` path
- `setRecording(false)` calls `setImage` with `tray_icon.png` path
- `setRecording(false)` when already idle is a no-op (no redundant `setImage` call)

### Integration (`test/app/home_page_test.dart`)
- Recording state triggers `setRecording(true)` on tray manager
- Idle/processing state triggers `setRecording(false)` on tray manager

## 26. Custom App & Tray Icon Tests

### Verification (manual)
- App icon in Dock and Finder shows custom duck icon, not Flutter logo
- Menu bar tray icon shows custom duck silhouette, not Flutter arrow
- Tray icon is visible in both light and dark macOS menu bar modes
- All icon sizes render clearly without artifacts (spot-check 16px and 1024px)
- `specs/icon-prompts.md` exists with generation prompts

**Note:** No Dart unit tests — icon assets are verified manually. The gate check (`fvm flutter analyze && fvm flutter test`) still applies to ensure no broken asset references.

## 27. Trailing Space on Text Insertion Tests

### ClipboardService (`test/core/services/clipboard_service_test.dart`)
- `pasteAtCursor("hello")` calls `insertTextWithFallback("hello ")` — trailing space appended
- `pasteAtCursor("hello ")` calls `insertTextWithFallback("hello ")` — no double space
- `pasteAtCursor("hello\n")` calls `insertTextWithFallback("hello\n")` — no space after newline
- `pasteAtCursor("")` calls `insertTextWithFallback("")` — empty string unchanged
- `copyToClipboard("hello")` sets clipboard to `"hello"` — no trailing space added

## 28. App Version Display Tests

### Settings page (`test/features/settings/ui/settings_page_test.dart`)
- Settings page renders version string at the bottom (e.g., "Version 1.1.0+2")
- Version text uses `bodySmall` text style
- Version is read from `PackageInfo` (mocked via `PackageInfo.setMockInitialValues()`)

### Model fetch with new providers (mocked HTTP)
- xAI `/models` response parsed correctly (model IDs like `grok-4-1-fast-non-reasoning`)
- Google Gemini `/models` response parsed correctly (model IDs like `gemini-3-flash`)
- OpenRouter `/models` response parsed correctly
- ModelFilter doesn't incorrectly exclude new provider model names
