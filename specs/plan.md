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

## Milestone Dependency Graph

```
M1 → M2 → M3 → M5
      │    │ ↘ M6 → M12
      │    └→ M9
      ├→ M7
      └→ M8 → M13
M3 + M4 → M5
M2 + M4 → M11
M1–M9 → M10
```
