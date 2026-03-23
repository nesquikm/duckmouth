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
8. Write E2E scenario: **Settings round-trip** — navigate to settings → change STT config (auto-saved) → verify new config persisted
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
1. Create `lib/core/api/models_client.dart` — HTTP client that calls `GET {baseUrl}/models` and returns model IDs (note: base URL includes version path, e.g. `https://api.openai.com/v1`)
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
- [x] `OutputMode.both` copies AND pastes
- [x] Paste errors fall back to copy gracefully
- [x] Osascript fallback removed
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M19: DMG Distribution & Homebrew Tap

**Goal:** Package the app as a distributable DMG and create a custom Homebrew tap for easy installation. No Apple Developer account — uses ad-hoc signing. Custom tap required because Homebrew 5.0.0 (Nov 2025) requires signing+notarization for core `homebrew/cask`.
**Prerequisites:** M1 (working app build)

**Tasks:**
1. Install `create-dmg` build dependency (`brew install create-dmg`)
2. Create `scripts/build_dmg.sh` — builds release, ad-hoc signs with `codesign -s -`, packages DMG with app icon + Applications shortcut via `create-dmg`
3. Extract version from `pubspec.yaml` automatically in build script
4. Test DMG: mount, drag-install to Applications, launch app
5. Create GitHub Release with DMG artifact (manual first, automate later)
6. Create `homebrew-duckmouth` custom tap repository with cask formula (`Casks/duckmouth.rb`)
7. Cask formula points to GitHub Release download URL, includes SHA256
8. Add `postflight` block to cask formula — strips quarantine via `xattr -dr com.apple.quarantine` (replaces deprecated `--no-quarantine` flag)
9. Add `zap` stanza to cask formula for clean uninstall of app data
10. Test `brew tap OWNER/duckmouth && brew install duckmouth` flow — verify postflight strips quarantine, app launches without Gatekeeper prompt
11. Test `brew upgrade` re-strips quarantine correctly
12. Add distribution instructions to project README (include manual DMG install workaround: `xattr -dr com.apple.quarantine`)

**Tests:**
- Build script runs without errors and produces DMG in `build/dmg/`
- DMG contains `.app` bundle with Applications symlink
- App inside DMG is ad-hoc signed (`codesign -v` passes)
- `brew audit --cask duckmouth` passes
- Installed via Homebrew — postflight strips quarantine, app launches without Gatekeeper prompt
- After `brew upgrade`, app still launches (postflight re-strips quarantine)
- `brew uninstall --zap` removes app data directories

**Acceptance Criteria:**
- [x] `scripts/build_dmg.sh` produces a working DMG in one command (AC-14.1, AC-14.8)
- [x] DMG has drag-to-install UX with Applications shortcut (AC-14.2)
- [x] App is ad-hoc signed inside the DMG (AC-14.3)
- [x] DMG hosted on GitHub Releases (AC-14.4)
- [x] Custom Homebrew tap repo with valid cask formula (AC-14.5)
- [x] Cask `postflight` strips quarantine via xattr (AC-14.6)
- [x] `brew tap && brew install` works, app launches clean (AC-14.7)
- [x] `zap` stanza cleans up app data (AC-14.9)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M20: Model Selection Fix

**Goal:** Always allow free-text model entry via autocomplete combo-box; fix PP preset defaulting to whisper models.
**Prerequisites:** M17

**Tasks:**
1. Add `llmModel` field to `ProviderPreset` enum (openAi → `gpt-4o-mini`, groq → `llama-3.3-70b-versatile`)
2. Rewrite `ModelDropdown` from `DropdownButtonFormField` to `RawAutocomplete<String>` — always renders a `TextField` for free typing, with fetched models as suggestions
3. Enable model text field for all presets (not just custom)
4. Fix `_onPpPresetChanged` to use `preset.llmModel` instead of `preset.model`
5. Update tests for autocomplete widget and llmModel field

**Tests:**
- ModelDropdown always shows TextField (not locked dropdown)
- Free-text typing works even after successful model fetch
- Autocomplete suggestions filter by typed text
- PP preset change sets LLM model (not whisper model)

**Acceptance Criteria:**
- [x] User can always type a custom model name for both STT and PP (AC-15.1)
- [x] Fetched models appear as autocomplete suggestions (AC-15.2)
- [x] Groq PP preset defaults to `llama-3.3-70b-versatile` (not whisper) (AC-15.3)
- [x] Provider presets have separate `model` and `llmModel` fields (AC-15.4)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M21: Auto-save Settings

**Goal:** Remove Save button; persist each setting immediately on change with debounce for text fields.
**Prerequisites:** M20

**Tasks:**
1. Add debounce timer and save-helper methods (`_saveSttConfig`, `_savePpConfig`, `_saveSoundConfig`, `_saveAudioFormatConfig`)
2. Wire text controllers with listeners for debounced auto-save (500ms)
3. Wire dropdowns, switches, and sliders to call cubit save methods immediately on change
4. Guard `didUpdateWidget` to only overwrite controllers when value differs (prevent save loops)
5. Remove `_onSave()` method and Save button
6. Update tests to verify auto-save behavior

**Tests:**
- Changing a dropdown triggers immediate save via cubit
- Text field changes trigger debounced save
- Save button is absent from the UI

**Acceptance Criteria:**
- [x] No Save button in settings (AC-16.1)
- [x] All settings persist immediately (dropdowns/switches) or after 500ms debounce (text fields) (AC-16.2, AC-16.3)
- [x] No save loops from cubit state re-emission (AC-16.4)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M22: Volume Preview Sound

**Goal:** Play the corresponding sound when a volume slider is released, so the user can hear the selected volume.
**Prerequisites:** M21

**Tasks:**
1. Add `onChangeEnd` parameter to `_VolumeSlider` widget, wire to `Slider.onChangeEnd`
2. On release: play the matching sound (start → Tink, stop → Pop, complete → Glass) at the selected volume
3. Trigger save on `onChangeEnd` (not debounced `onChanged`) for volume values

**Tests:**
- Releasing a volume slider plays the corresponding sound at the correct volume

**Acceptance Criteria:**
- [x] Releasing "Recording start volume" slider plays Tink at selected volume (AC-17.1)
- [x] Releasing "Recording stop volume" slider plays Pop at selected volume (AC-17.1)
- [x] Releasing "Transcription complete volume" slider plays Glass at selected volume (AC-17.1)
- [x] Volume saved on slider release (AC-17.2)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M23: Dark Mode Banner Colors

**Goal:** Fix accessibility permission banners to use theme-aware colors visible in both light and dark modes.
**Prerequisites:** M4

**Tasks:**
1. In `_AccessibilityPermissionBanner` (settings_page.dart): check brightness, use dark-appropriate background/icon colors
2. In `_AccessibilityBanner` (home_page.dart): same dark-mode-aware color treatment
3. Add explicit `iconColor` for proper contrast in both modes

**Tests:**
- Banner renders different colors in light vs dark theme

**Acceptance Criteria:**
- [x] "Accessibility permission granted" banner is clearly visible in dark mode (AC-18.1)
- [x] Warning and unknown banners also adapt to dark mode (AC-18.1)
- [x] Icon colors have proper contrast in both themes (AC-18.2)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M24: Model Fetch Diagnostics & Base URL Migration

**Goal:** Show specific error messages when model fetch fails (not just "Could not load models"). Move `/v1` from hardcoded API clients into provider base URLs to support providers with different path structures (e.g. Google Gemini).
**Prerequisites:** M17 (Dynamic Model Discovery), M20 (Model Selection Fix)

**Tasks:**
1. Create `FetchModelsResult` sealed class with `FetchModelsSuccess(List<String> models)` and `FetchModelsFailure(String reason)` variants
2. Update `ModelsClient.fetchModels` to return `FetchModelsResult` — map HTTP status codes to specific error messages (401 → "Unauthorized — check API key", 404 → "Not found — check endpoint URL", network error → "Network error — check connection", malformed JSON → "Unexpected response format")
3. Update `ModelDropdown` to display `FetchModelsFailure.reason` in helper text instead of generic "Could not load models — type manually"
4. Remove hardcoded `/v1/` from `OpenAiClientImpl` (`$baseUrl/v1/audio/transcriptions` → `$baseUrl/audio/transcriptions`)
5. Remove hardcoded `/v1/` from `LlmClientImpl` (`$baseUrl/v1/chat/completions` → `$baseUrl/chat/completions`)
6. Remove hardcoded `/v1/` from `ModelsClientImpl` (`$baseUrl/v1/models` → `$baseUrl/models`)
7. Update `ProviderPreset` base URLs: OpenAI → `https://api.openai.com/v1`, Groq → `https://api.groq.com/openai/v1`
8. Add migration in `SettingsRepositoryImpl` — on load, if saved `baseUrl` matches a known old-format value (e.g. `https://api.openai.com`), append `/v1`; if already migrated, leave unchanged
9. Update all tests for new result type, updated base URLs, and migration logic

**Tests:**
- `FetchModelsResult` sealed class: success with model list, failure with reason string
- `ModelsClient` returns specific error messages for 401, 403, 404, 429, 5xx, network error, malformed JSON
- `ModelDropdown` displays failure reason from result (not generic message)
- API clients construct correct URLs without `/v1/` prefix (e.g. `https://api.openai.com/v1/models`)
- Provider presets have updated base URLs with version path
- Settings migration appends `/v1` to old-format OpenAI/Groq URLs
- Migration is idempotent (doesn't double-append)
- Migration does not touch custom/unknown URLs

**Acceptance Criteria:**
- [x] Model fetch errors show specific reason in helper text (AC-19.1, AC-19.2, AC-19.3)
- [x] Model field stays editable on error (AC-19.4)
- [x] `ModelsClient` returns result type with error detail (AC-19.5)
- [x] API clients use `baseUrl` directly without adding `/v1/` (AC-20.1)
- [x] Provider preset URLs include version path (AC-20.2)
- [x] Saved settings migrated on load (AC-20.3)
- [x] Custom base URLs work unchanged (AC-20.4)
- [x] All existing functionality works unchanged (AC-20.5)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M25: Additional Provider Presets

**Goal:** Add xAI (Grok), Google Gemini, and OpenRouter as provider presets. Models are fetched dynamically; default model names are initial suggestions only.
**Prerequisites:** M24 (base URL migration must be done first so non-`/v1` providers work)

**Tasks:**
1. Add `xAi` preset to `ProviderPreset`: label `"xAI (Grok)"`, baseUrl `https://api.x.ai/v1`, model `""` (no STT), llmModel `grok-4-1-fast-non-reasoning`
2. Add `googleGemini` preset to `ProviderPreset`: label `"Google Gemini"`, baseUrl `https://generativelanguage.googleapis.com/v1beta/openai`, model `""` (no STT), llmModel `gemini-3-flash`
3. Add `openRouter` preset to `ProviderPreset`: label `"OpenRouter"`, baseUrl `https://openrouter.ai/api/v1`, model `""` (no STT), llmModel `openrouter/auto`
4. Update `ModelDropdown` to show hint text `"This provider has no STT models"` when the preset's default STT model is empty and `modelType` is `ModelType.stt`
5. Verify `ModelFilter` doesn't incorrectly exclude new provider model names (e.g. `grok-*`, `gemini-*`)
6. Update all preset-related tests for 6 presets (OpenAI, Groq, xAI, Google Gemini, OpenRouter, Custom)

**Tests:**
- Each new preset has correct label, baseUrl, model, llmModel values
- `fromName` resolves `xAi`, `googleGemini`, `openRouter` correctly
- `toApiConfig` works for all new presets
- Provider dropdown includes all 6 presets in both STT and PP sections
- Selecting xAI/Gemini/OpenRouter for STT shows "no STT models" hint
- Model fetch returns models from each new provider (mocked HTTP responses)
- `ModelFilter` doesn't incorrectly exclude `grok-*`, `gemini-*`, `openrouter/*` model names

**Acceptance Criteria:**
- [x] xAI preset available with correct defaults (AC-21.1)
- [x] Google Gemini preset available with correct defaults (AC-21.2)
- [x] OpenRouter preset available with correct defaults (AC-21.3)
- [x] All presets visible in provider dropdown (AC-21.4)
- [x] STT-less providers show appropriate hint (AC-21.5)
- [x] Model fetch works for all new providers (AC-21.6)
- [x] STT and LLM calls work with supporting providers (AC-21.7)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M26: In-App Log Viewer

**Goal:** Add an in-app log viewer using `the_logger_viewer_widget`, accessible from the home page AppBar. Upgrade `the_logger` to pub.dev `^0.0.20` for streaming support.
**Prerequisites:** M16 (Structured Logging)

**Tasks:**
1. Change `the_logger` from path dependency to pub.dev `^0.0.20` in `pubspec.yaml`
2. Add `the_logger_viewer_widget: ^0.0.2` to `pubspec.yaml`
3. Run `fvm flutter pub get` and verify resolution
4. Add `_LogsButton` widget to home page AppBar actions (pushes `TheLoggerViewerPage`)
5. Verify existing logging setup tests pass with `the_logger` 0.0.20
6. Write widget test for Logs button navigation in `test/app/home_page_test.dart`

**Tests:**
- Home AppBar shows Logs icon button
- Tapping Logs button navigates to `TheLoggerViewerPage`
- Existing logging setup tests pass after dependency upgrade
- Gate passes

**Acceptance Criteria:**
- [x] `the_logger` is pub.dev `^0.0.20` (not path) (AC-22.1)
- [x] `the_logger_viewer_widget: ^0.0.2` in pubspec.yaml (AC-22.2)
- [x] "Logs" button in home AppBar opens log viewer page (AC-22.3)
- [x] Log viewer shows real-time streaming updates (AC-22.4)
- [x] Filtering by level, search, and logger name works (AC-22.5)
- [x] Session navigation works (AC-22.6)
- [x] Available in release builds (AC-22.7)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M27: Trailing Space on Text Insertion

**Goal:** Append a trailing space when inserting text at the cursor so the user can continue typing immediately.
**Prerequisites:** M6 (Text Output)

**Tasks:**
1. Add trailing space logic to `ClipboardServiceImpl.pasteAtCursor()` with whitespace guard
2. Update existing clipboard service tests for new behavior
3. Add new test cases for trailing space, no-double-space, and newline guard

**Tests:**
- `pasteAtCursor` appends space to text without trailing whitespace
- `pasteAtCursor` does not double-space text ending with space
- `pasteAtCursor` does not add space after newline
- `copyToClipboard` is not affected
- Gate passes

**Acceptance Criteria:**
- [x] Inserted text has trailing space (AC-23.1)
- [x] Clipboard copy unchanged (AC-23.2)
- [x] No extra space if text already ends with whitespace (AC-23.3)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M28: Custom App & Tray Icons

**Goal:** Replace default Flutter icons with custom Duckmouth branding for both the app icon and menu bar tray icon.
**Prerequisites:** M1 (Foundation & App Shell)

**Tasks:**
1. Write icon generation prompts to `specs/icon-prompts.md`
2. Generate app icon artwork via Nano Banana (1024px source)
3. Generate tray icon artwork via Nano Banana (monochrome silhouette)
4. Downscale app icon to all required sizes (16, 32, 64, 128, 256, 512, 1024px) and replace files in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
5. Replace `assets/tray_icon.png` with new monochrome tray icon
6. Verify icons render correctly in Dock, Finder, and menu bar
7. Verify DMG build still works with new icon

**Tests:**
- Manual: app icon visible in Dock and Finder
- Manual: tray icon visible in menu bar (light and dark mode)
- Manual: all sizes render cleanly
- Gate passes (no broken asset references)

**Acceptance Criteria:**
- [x] Custom app icon at all macOS sizes (AC-24.1)
- [x] Custom monochrome tray icon (AC-24.2)
- [x] Icon prompts saved in `specs/icon-prompts.md` (AC-24.3)
- [x] DMG branding updated if applicable (AC-24.4)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M29: Hotkey Rapid Press Race Condition Fix

**Goal:** Fix race condition where rapid hotkey press/release leaves the app stuck in recording state.
**Prerequisites:** M7 (Global Hotkeys), M2 (Audio Recording)

**Tasks:**
1. Add `_startInProgress` and `_pendingStop` flags to `RecordingCubit`
2. Guard `stopRecording()` to set `_pendingStop` if start is in progress
3. Auto-call `stopRecording()` in `startRecording()`'s `finally` block when `_pendingStop` is true
4. Reset `_pendingStop` on new `startRecording()` call
5. Add tests for rapid press/release scenarios
6. Verify normal start/stop flow is unaffected

**Tests:**
- Stop during start sets pending flag, auto-stops after start completes
- Final state is not stuck in `RecordingInProgress`
- Normal flow unaffected
- Toggle mode rapid double-tap works
- Gate passes

**Acceptance Criteria:**
- [x] Rapid push-to-talk does not hang (AC-25.1)
- [x] Pending stop fires after start completes (AC-25.2)
- [x] Toggle mode handles rapid input (AC-25.3)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M30: Theme Selection

**Goal:** Add theme mode selector (System/Dark/Light) to settings.
**Prerequisites:** M4 (Settings), M21 (Auto-save Settings)

**Tasks:**
1. Add `AppThemeMode` enum and `themeMode` field to `SettingsLoaded` state
2. Add persistence for `theme_mode` in `SettingsRepositoryImpl` (SharedPreferences)
3. Add `saveThemeMode()` to `SettingsCubit`
4. Move `SettingsCubit` provider up from `HomePage` to `DuckmouthApp` level
5. Wrap `MaterialApp` in `BlocBuilder<SettingsCubit>` to apply `ThemeMode` reactively
6. Add theme mode dropdown to settings page in an "Appearance" section
7. Wire dropdown to auto-save on change
8. Write tests for cubit, persistence, settings UI, and app widget

**Tests:**
- Default theme mode is system
- Theme mode persisted and loaded correctly
- Selecting dark/light applies immediately
- Settings dropdown shows three options
- App widget reacts to cubit state changes
- Gate passes

**Acceptance Criteria:**
- [x] Theme dropdown in settings with System/Dark/Light (AC-26.1)
- [x] Theme applies immediately on selection (AC-26.2)
- [x] System mode follows OS appearance (AC-26.3)
- [x] Theme preference persisted (AC-26.4)
- [x] Default is System (AC-26.5)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M31: Branded Color Scheme

**Goal:** Replace default Material purple seed color with duck amber from the app icon so both themes match Duckmouth branding.
**Prerequisites:** M30 (Theme Selection)

**Tasks:**
1. Change seed color in `AppTheme` from `0xFF6750A4` to `0xFFE8A838`
2. Write unit tests for `AppTheme` verifying seed color and brightness
3. Visual verification that light and dark themes look correct

**Tests:**
- Light theme uses branded seed color
- Dark theme uses branded seed color
- Both themes use Material 3
- Gate passes

**Acceptance Criteria:**
- [x] Seed color is duck amber `0xFFE8A838` (AC-27.1)
- [x] Both light and dark themes use branded seed (AC-27.2)
- [x] All UI elements render correctly (AC-27.3)
- [x] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M32: Tray Icon Click to Show Window

**Goal:** Left-clicking the tray icon brings the app window to front (currently does nothing).
**Prerequisites:** M7 (Global Hotkeys — tray already exists)

**Tasks:**
1. Register `registerSystemTrayEventHandler` in `SystemTrayManager.init()` to handle `kSystemTrayEventClick`
2. Add debounce guard (300ms) to prevent duplicate show on double-click
3. Wire click handler to call `_onShow` callback
4. Write unit tests for click handling and debounce

**Tests:**
- Left-click triggers onShow callback
- Right-click does not trigger onShow
- Double-click only triggers onShow once
- Gate passes

**Acceptance Criteria:**
- [ ] Left-click shows app window (AC-28.1)
- [ ] Right-click context menu still works (AC-28.2)
- [ ] Double-click debounced (AC-28.3)
- [ ] Gate passes: `fvm flutter analyze && fvm flutter test`

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## M33: Tray Icon Recording Indicator

**Goal:** Tray icon visually indicates when the app is recording via a red dot overlay.
**Prerequisites:** M2 (Audio Recording), M28 (Custom App & Tray Icons)

**Tasks:**
1. Create `tray_icon_recording.png` asset — duck silhouette with red dot overlay
2. Add `setRecording(bool)` method to `SystemTrayManager` that swaps icon via `setImage()`
3. Call `setRecording(true/false)` from existing BLoC listeners in `home_page.dart`
4. Write unit and integration tests

**Tests:**
- `setRecording(true)` swaps to recording icon
- `setRecording(false)` swaps to default icon
- Recording state in cubit triggers icon swap
- Gate passes

**Acceptance Criteria:**
- [ ] Recording icon shown when recording (AC-29.1)
- [ ] Default icon restored when recording stops (AC-29.2)
- [ ] Recording icon visible in light and dark menu bar (AC-29.3)
- [ ] Second icon asset exists (AC-29.4)
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
M1 → M19
M17 → M20 → M21 → M22
M4 → M23
M17 + M20 → M24 → M25
M16 → M26
M6 → M27
M1 → M28
M2 + M7 → M29
M4 + M21 → M30
M30 → M31
M7 → M32
M2 + M28 → M33
```
