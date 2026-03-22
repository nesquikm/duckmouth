# Implementation Plan

## Milestone Order

Each milestone is independently gatable. Don't proceed to M(n+1) until M(n) gates pass.

## M1: Foundation & App Shell

**Goal:** Working macOS app with menu bar presence, basic window, and project architecture in place.
**Prerequisites:** None

**Tasks:**
1. Set up feature-first directory structure (`lib/app/`, `lib/features/`, `lib/core/`)
2. Configure dependency injection setup (`lib/core/di/`)
3. Create app shell with main window and basic routing
4. Add menu bar icon with empty popover (system_tray)
5. Set up theme and design tokens

**Tests:**
- App widget renders without error
- DI container resolves dependencies

**Acceptance Criteria:**
- [x] App launches on macOS with a window
- [x] Menu bar icon appears
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M2: Audio Recording

**Goal:** Capture audio from microphone, display recording state in UI.
**Prerequisites:** M1

**Tasks:**
1. Add `record` package, configure macOS microphone permission
2. Implement recording repository (start, stop, get audio data)
3. Create RecordingCubit with states (idle, recording, processing)
4. Build recording controls UI (start/stop button, duration display)
5. Wire up recording to menu bar popover

**Tests:**
- RecordingCubit state transitions
- Recording repository with mocked audio plugin

**Acceptance Criteria:**
- [x] Can start/stop recording via UI
- [x] Recording duration displayed in real-time
- [x] Audio data available after recording stops
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M3: STT Transcription

**Goal:** Send recorded audio to STT API and display result.
**Prerequisites:** M2

**Tasks:**
1. Implement OpenAI-compatible HTTP client (`lib/core/api/`)
2. Implement STT repository (send audio, get text)
3. Create TranscriptionCubit
4. Build transcription display UI
5. Wire recording → transcription pipeline

**Tests:**
- API client constructs correct requests
- TranscriptionCubit state transitions with mocked repo
- Error handling (network failure, invalid response)

**Acceptance Criteria:**
- [x] Recording is sent to configured STT endpoint
- [x] Transcription text displayed in UI
- [x] Errors shown gracefully
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M4: Settings & API Configuration

**Goal:** Full settings UI with API provider configuration and secure key storage.
**Prerequisites:** M3

**Tasks:**
1. Add flutter_secure_storage and shared_preferences
2. Implement settings repository (read/write settings, secure API keys)
3. Create SettingsCubit
4. Build settings screens (API config, provider presets)
5. Wire settings to STT client

**Tests:**
- SettingsCubit state management
- Settings repository with mocked storage
- Provider preset configuration

**Acceptance Criteria:**
- [x] Can configure API endpoint, key, and model
- [x] Provider presets (OpenAI, Groq) pre-fill settings
- [x] API keys stored in macOS Keychain
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M5: Post-Processing

**Goal:** Optional LLM post-processing of transcription results.
**Prerequisites:** M3, M4

**Tasks:**
1. Implement LLM chat completions client (reuse OpenAI-compatible base)
2. Add post-processing toggle and prompt configuration to settings
3. Create PostProcessingCubit
4. Wire into transcription pipeline (raw → post-processed)
5. Show both raw and processed text in UI

**Tests:**
- LLM client request/response
- PostProcessingCubit with mocked LLM repo
- Pipeline with post-processing enabled/disabled

**Acceptance Criteria:**
- [x] Post-processing can be toggled on/off
- [x] Custom prompts applied to transcription
- [x] Raw text preserved, processed text displayed
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M6: Text Output (Clipboard & Paste)

**Goal:** Copy result to clipboard and/or paste at cursor position.
**Prerequisites:** M3

**Tasks:**
1. Implement clipboard service
2. Implement paste-at-cursor via clipboard sandwich
3. Add output mode setting (copy, paste, both)
4. Auto-trigger output on transcription complete

**Tests:**
- Clipboard service with mocked platform channel
- Output mode configuration

**Acceptance Criteria:**
- [x] Result copied to clipboard
- [x] Paste-at-cursor works via clipboard sandwich
- [x] Output mode configurable
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M7: Global Hotkeys

**Goal:** Configurable global shortcuts for push-to-talk and toggle recording.
**Prerequisites:** M2

**Tasks:**
1. Add hotkey_manager package, configure macOS permissions
2. Implement hotkey registration service
3. Add hotkey configuration to settings UI
4. Support push-to-talk (hold) and toggle (press) modes

**Tests:**
- Hotkey cubit state transitions
- Mode switching logic

**Acceptance Criteria:**
- [x] Global hotkey starts/stops recording
- [x] Push-to-talk and toggle modes work
- [x] Hotkey configurable in settings
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M8: Sound Feedback

**Goal:** Audio feedback for recording events.
**Prerequisites:** M2

**Tasks:**
1. Add sound assets (start, stop, complete)
2. Implement sound playback service
3. Add sound settings (enable/disable, per-sound volume)
4. Trigger sounds on recording start, stop, transcription complete

**Tests:**
- Sound service with mocked audio player
- Sound settings persistence

**Acceptance Criteria:**
- [x] Sounds play on recording start, stop, and transcription complete
- [x] Sounds can be enabled/disabled
- [x] Per-sound volume control works
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M9: Transcription History

**Goal:** Persistent list of past transcriptions.
**Prerequisites:** M3

**Tasks:**
1. Implement local history storage (SQLite or JSON file)
2. Create HistoryCubit
3. Build history list UI with timestamps
4. Click to copy, clear history option
5. Show recent items in menu bar popover

**Tests:**
- History repository CRUD operations
- HistoryCubit state management
- History UI widget tests

**Acceptance Criteria:**
- [x] History shows transcriptions with timestamps
- [x] Click to copy works
- [x] Clear history works
- [x] Recent items in menu bar popover
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M10: Polish & Integration

**Goal:** Final integration, UI polish, edge cases.
**Prerequisites:** M1–M9

**Tasks:**
1. End-to-end flow testing (record → transcribe → post-process → output)
2. Menu bar popover polish (status, recent items, quick actions)
3. Error handling edge cases (no mic, network down, invalid API key)
4. Audio input device selection in settings
5. macOS permissions handling (microphone, accessibility for paste)

**Tests:**
- Integration tests for full pipeline
- Error state UI tests

**Acceptance Criteria:**
- [x] Full flow works end-to-end
- [x] All settings functional
- [x] Error states handled gracefully
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M11: Audio Format & Quality

**Goal:** Let users choose recording format and quality, with smart defaults.
**Prerequisites:** M2, M4

**Tasks:**
1. Add audio format enum: WAV, FLAC, AAC (m4a), Opus (ogg) — matching what Flutter `record` supports on macOS
2. Add quality preset enum: "Best compatibility" (WAV 16kHz 16-bit mono — works everywhere including whisper.cpp), "Balanced" (AAC 64kbps 16kHz mono — good size/quality), "Smallest" (AAC 32kbps 16kHz mono)
3. Add format/quality settings to SettingsCubit and settings UI
4. Wire format config into recording repository (configure `record` package encoder)
5. Add info text explaining tradeoffs per format (especially whisper.cpp WAV requirement)

**Tests:**
- Settings cubit handles format/quality changes
- Recording repository configures encoder correctly per format
- Default format produces valid audio accepted by OpenAI API

**Acceptance Criteria:**
- [x] User can select audio format (WAV, FLAC, AAC, Opus)
- [x] Quality presets available with clear descriptions
- [x] Default is WAV 16kHz mono (maximum compatibility)
- [x] Recording produces correct format based on settings
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M12: Accessibility API Text Insertion

**Goal:** Replace osascript clipboard sandwich with native Accessibility API for direct text insertion, with intelligent fallback chain. Prompt user for Accessibility permission.
**Prerequisites:** M6

**Tasks:**
1. Add Swift platform channel (`TextInsertionChannel`) in `macos/Runner/`
2. Implement `AXUIElementSetAttributeValue` with `kAXSelectedTextAttribute` — directly sets text at cursor in the focused app without touching the clipboard
3. Implement `CGEvent` Cmd+V fallback — same as current clipboard sandwich but without subprocess overhead (no `osascript`)
4. Implement Accessibility permission check via `AXIsProcessTrusted()` / `AXIsProcessTrustedWithOptions()` with prompt
5. Create `AccessibilityService` in `lib/core/services/` wrapping the platform channel
6. Add permission status UI: banner/dialog prompting user to enable Accessibility in System Settings → Privacy & Security → Accessibility
7. Update `ClipboardService.pasteAtCursor()` to use the fallback chain: AX direct insert → CGEvent Cmd+V with clipboard sandwich → osascript (legacy fallback)
8. Add Accessibility permission status to settings page

**Fallback chain:**
1. **AX direct insert** (`kAXSelectedTextAttribute`) — no clipboard touch, instant. Fails silently in Electron/web apps.
2. **CGEvent Cmd+V** — clipboard sandwich via native CGEvent (fast, no subprocess). Requires Accessibility permission.
3. **osascript Cmd+V** — current approach, kept as last resort.

**Tests:**
- AccessibilityService platform channel communication with mocked method channel
- Permission check returns correct status (granted, denied, unknown)
- Fallback chain: AX fails → CGEvent attempted → osascript attempted
- ClipboardService integration with AccessibilityService
- Permission UI shows/hides based on permission state

**Acceptance Criteria:**
- [x] Text inserted at cursor via Accessibility API in native macOS apps (TextEdit, Notes, etc.)
- [x] Graceful fallback to CGEvent Cmd+V when AX insert fails
- [x] Final fallback to osascript preserves existing behavior
- [x] App prompts user for Accessibility permission on first paste attempt
- [x] Permission status visible in settings
- [x] No clipboard clobbering when AX direct insert succeeds
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M13: Native Sound Playback

**Goal:** Replace `afplay` process spawning with native NSSound via Flutter platform channel. Fixes sandbox compatibility and reduces latency.
**Prerequisites:** M8

**Tasks:**
1. Add Swift platform channel (`SoundChannel`) in `macos/Runner/`
2. Implement `NSSound(named:)` playback with volume control via `NSSound.volume`
3. Replace `SoundServiceImpl` to use `MethodChannel` instead of `Process.run('afplay', ...)`
4. Remove `dart:io` dependency from sound service

**Tests:**
- SoundService platform channel communication with mocked MethodChannel
- Volume is clamped and passed correctly
- Playback errors handled gracefully (sound not found, channel unavailable)
- Existing sound settings and triggers unchanged

**Acceptance Criteria:**
- [x] Sounds play via NSSound instead of afplay
- [x] Works in sandboxed release builds
- [x] Volume control preserved
- [x] No process spawning for sound playback
- [x] Existing sound enable/disable and per-sound volume settings still work
- [x] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M14: End-to-End Integration Tests

**Goal:** Full-app integration tests that launch the real app with mocked backends, exercising the complete user flow from recording through transcription, post-processing, and output — all driven programmatically.
**Prerequisites:** M10

**Tasks:**
1. Create `integration_test/` directory with Flutter integration test driver (`integration_test_driver.dart`)
2. Build test harness that overrides `setupServiceLocator()` with fakes:
   - `FakeRecordingRepository` — simulates mic capture, returns a canned audio file
   - `FakeSttRepository` — returns canned transcription text (no HTTP)
   - `FakePostProcessingRepository` — returns canned processed text (no HTTP)
   - `FakeSoundService` — no-op (no NSSound platform channel needed)
   - `FakeAccessibilityService` — no-op (no AX platform channel needed)
   - `FakeClipboardService` — captures output text for assertion
   - `FakeHotkeyService` — no-op (no native hotkey registration)
3. Create test fixtures: canned transcription responses, prompt templates, settings configs
4. Write E2E scenario: **Happy path** — app launches → tap record → recording completes → transcription succeeds → post-processing succeeds → result displayed → history entry created
5. Write E2E scenario: **STT error & retry** — recording completes → transcription fails → error shown → tap retry → transcription succeeds
6. Write E2E scenario: **Post-processing disabled** — recording → transcription → post-processing skipped → raw text shown and copied
7. Write E2E scenario: **Post-processing error & retry** — transcription succeeds → post-processing fails → error shown → tap retry → succeeds
8. Write E2E scenario: **Settings round-trip** — navigate to settings → change STT config → save → verify new config persisted
9. Write E2E scenario: **History** — complete a transcription → navigate to history → verify entry visible → swipe to delete → verify removal
10. Add `integration_test` to gate check documentation (optional: separate from unit gate since it requires macOS runner)

**Test Infrastructure:**
- Use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` for real app bootstrapping
- Override GetIt registrations before `pumpWidget(DuckmouthApp())`
- Use `SharedPreferences.setMockInitialValues()` for deterministic settings
- All fakes implement existing abstract interfaces — no API calls, no platform channels
- `tester.runAsync()` for tap operations that trigger async cubit flows

**Tests:**
- Happy path: record → transcribe → post-process → output → history
- Error recovery: STT failure → retry → success
- Error recovery: post-processing failure → retry → success
- Feature toggle: post-processing disabled → raw text output
- Settings persistence: change config → reload → config retained
- History CRUD: create entry → view → delete

**Acceptance Criteria:**
- [x] `integration_test/` directory with Flutter integration test driver
- [x] Test harness with fake services (no HTTP, no platform channels)
- [x] Happy path E2E passes: record → transcribe → post-process → verify output
- [x] Error + retry E2E passes for both STT and post-processing
- [x] Settings and history E2E scenarios pass
- [x] All fakes implement production interfaces (type-safe)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`
- [x] Integration tests runnable via `fvm flutter test integration_test/`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M15: Hotkey System Fix — Recorder, Key Codes, Display

**Goal:** Fix all three hotkey issues: registration silently failing (wrong key code format), recorder capturing bare modifiers, and hex codes in the UI.
**Prerequisites:** M7 (Global Hotkeys)

**Background:**
The hotkey_manager plugin's native Swift layer expects Carbon key codes (e.g. `49` for Space), but the app sends USB HID usage codes (`0x0007002C`). The plugin's `HotKeyRecorder` widget fires immediately on any key event including bare modifiers. The settings UI shows raw hex codes for unrecognized keys.

**Tasks:**
1. Create `key_code_translator.dart` with USB HID ↔ Carbon mapping and human-readable labels
2. Update `HotkeyConfig.toHotKey()` to translate USB HID → Carbon before sending to native plugin
3. Build custom `HotkeyRecorderDialog` that waits for modifier+key combo (replaces `HotKeyRecorder` widget)
4. Update settings page to use new recorder dialog and display human-readable labels
5. Update `_hotkeyDisplayLabel` / `_keyCodeToLabel` to use the translator
6. Add comprehensive tests for translator, recorder, and display

**Tests:**
- Key code translator: USB HID → Carbon mapping for all common keys
- Key code translator: USB HID → label for all common keys
- Custom recorder: bare modifier doesn't fire callback
- Custom recorder: modifier+key combo fires with correct config
- Custom recorder: escape cancels
- Hotkey display: shows human-readable labels
- Hotkey registration: translated Carbon code reaches native plugin
- Round-trip: record → save → reload → display matches

**Acceptance Criteria:**
- [x] Global hotkey actually triggers recording (Carbon codes sent to native)
- [x] Hotkey recorder waits for full modifier+key combo
- [x] Settings UI shows "Ctrl + Shift + Space" format, not hex codes
- [x] All existing hotkey tests updated and passing
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M16: Structured Logging (the_logger)

**Goal:** Integrate the_logger for structured, level-based console logging with sensitive data masking. Console output only — no log viewer or export UI.
**Prerequisites:** M4 (Settings — for API key masking hookup)

**Tasks:**
1. Add `the_logger` (path dependency: `~/workspace/the/the_logger`) and `logging` to `pubspec.yaml`
2. Create `lib/core/logging/logging_setup.dart` with `setupLogging()` — calls `TheLogger.i().init(dbLogger: false)` with app version in `sessionStartExtra`
3. Call `setupLogging()` in `main()` before `runApp()`
4. Add `Logger` instances to key services: `RecordingRepositoryImpl`, `SttRepositoryImpl`, `PostProcessingRepositoryImpl`, `ClipboardService`, `AccessibilityService`, `SoundService`, `HotkeyCubit`, `SettingsCubit`, `OpenAIClient`, `LlmClient`
5. Add API key masking in `SettingsCubit` — call `addMaskingString` when keys are loaded/changed, `removeMaskingString` when keys are cleared
6. Replace all `print()` / `debugPrint()` calls in `lib/` with appropriate `Logger` level calls
7. Log errors with `Logger.severe(message, error, stackTrace)` in all catch blocks
8. Add logging setup tests

**Tests:**
- `setupLogging()` initializes correctly with dbLogger disabled
- API key masking: key is redacted, empty key skipped, key change updates masking
- No remaining `print()`/`debugPrint()` in `lib/` (grep check)

**Acceptance Criteria:**
- [x] `the_logger` initialized in `main()` with console-only config
- [x] All key services use named `Logger` instances
- [x] API keys masked in console output
- [x] No `print()`/`debugPrint()` remaining in `lib/`
- [x] Errors logged with `.severe()` including error objects
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M17: Dynamic Model Discovery

**Goal:** Replace free-text model fields with dropdowns that fetch available models from the provider's `/v1/models` endpoint. Applies to both STT and LLM (post-processing) sections in Settings.
**Prerequisites:** M4 (Settings & API Configuration)

**Tasks:**
1. Create `lib/core/api/models_client.dart` — HTTP client that calls `GET {baseUrl}/v1/models` and returns `List<String>` of model IDs
2. Create `lib/core/api/model_filter.dart` — heuristic filters to classify models as STT (contains `whisper`) vs LLM (excludes embedding/tts/image patterns)
3. Create `lib/features/settings/ui/model_dropdown.dart` — reusable widget: dropdown when models loaded, free-text fallback on error, loading spinner while fetching
4. Replace STT model `TextField` in `settings_page.dart` with `ModelDropdown` using STT filter
5. Replace LLM model `TextField` in `settings_page.dart` with `ModelDropdown` using LLM filter
6. Trigger model list refresh when base URL or API key changes in `SettingsCubit`
7. Add `ModelsClient` to service locator
8. Write unit tests for `ModelsClient`, `ModelFilter`, and `ModelDropdown`

**Tests:**
- `ModelsClient` parses response, handles errors gracefully
- `ModelFilter` correctly classifies STT vs LLM models
- `ModelDropdown` shows loading → dropdown on success, loading → text field on failure
- Model list refreshes on provider config change
- Free-text fallback works when API doesn't support `/v1/models`

**Acceptance Criteria:**
- [x] STT model field is a dropdown populated from `/v1/models` (AC-13.1, AC-13.2)
- [x] LLM model field is a dropdown populated from `/v1/models` (AC-13.1, AC-13.3)
- [x] Model list refreshes when base URL or API key changes (AC-13.4)
- [x] Falls back to free-text on API error without blocking user (AC-13.5)
- [x] Loading indicator while fetching (AC-13.6)
- [x] Works with OpenAI, Groq, and custom endpoints (AC-13.7)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M18: Output Pipeline Hardening

**Goal:** Fix remaining edge cases in the text output path.
**Prerequisites:** M6 (Text Output), M12 (Accessibility API)

**Tasks:**
1. Fix `OutputMode.both`: currently only calls `pasteAtCursor`, should also call `copyToClipboard`
2. Add try/catch to `_handleOutput` — currently fire-and-forget; paste failure should fall back to copy
3. Remove osascript legacy fallback from `AccessibilityService` — can't work in a sandbox, and CGEvent paste covers the same path

**Tests:**
- `OutputMode.both` calls both `copyToClipboard` and `pasteAtCursor`
- Error in paste path falls back to copy gracefully

**Acceptance Criteria:**
- [ ] `OutputMode.both` copies AND pastes
- [ ] Paste errors fall back to copy gracefully
- [ ] Osascript fallback removed
- [ ] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## Milestone Dependency Graph

```
M1 → M2 → M3 → M5
      │    │ ↘ M6 → M12
      │    └→ M9
      ├→ M7 → M15
      └→ M8 → M13
M3 + M4 → M5
M2 + M4 → M11
M1–M9 → M10
M10 → M14
M4 → M16
M4 → M17
M6 + M12 + M16 → M18
```
