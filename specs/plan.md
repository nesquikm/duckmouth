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
- [ ] App launches on macOS with a window
- [ ] Menu bar icon appears
- [ ] Gate passes: `fvm flutter analyze && fvm flutter test`

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
- [ ] Can start/stop recording via UI
- [ ] Recording duration displayed in real-time
- [ ] Audio data available after recording stops
- [ ] Gate passes

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
- [ ] Recording is sent to configured STT endpoint
- [ ] Transcription text displayed in UI
- [ ] Errors shown gracefully
- [ ] Gate passes

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
- [ ] Can configure API endpoint, key, and model
- [ ] Provider presets (OpenAI, Groq) pre-fill settings
- [ ] API keys stored in macOS Keychain
- [ ] Gate passes

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
- [ ] Post-processing can be toggled on/off
- [ ] Custom prompts applied to transcription
- [ ] Raw text preserved, processed text displayed
- [ ] Gate passes

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
- [ ] Result copied to clipboard
- [ ] Paste-at-cursor works via clipboard sandwich
- [ ] Output mode configurable
- [ ] Gate passes

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
- [ ] Global hotkey starts/stops recording
- [ ] Push-to-talk and toggle modes work
- [ ] Hotkey configurable in settings
- [ ] Gate passes

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
- [ ] Sounds play on recording start, stop, and transcription complete
- [ ] Sounds can be enabled/disabled
- [ ] Per-sound volume control works
- [ ] Gate passes

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
- [ ] History shows transcriptions with timestamps
- [ ] Click to copy works
- [ ] Clear history works
- [ ] Recent items in menu bar popover
- [ ] Gate passes

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
- [ ] Full flow works end-to-end
- [ ] All settings functional
- [ ] Error states handled gracefully
- [ ] Gate passes

**Gate:** `fvm flutter analyze && fvm flutter test`

---

## Milestone Dependency Graph

```
M1 → M2 → M3 → M5
      │    │ ↘ M6
      │    └→ M9
      ├→ M7
      └→ M8
M3 + M4 → M5
M1–M9 → M10
```
