# Requirements

## 1. Overview

Duckmouth is a macOS desktop app that captures speech via microphone, transcribes it using an OpenAI-compatible STT API, and optionally post-processes the result with LLM prompts. It supports global hotkeys and lives in both the menu bar and as a regular app window.

**Target user:** Anyone who needs fast speech-to-text on macOS with flexible API backends and post-processing.

## 2. Functional Requirements

### FR-1: Audio Recording

**Description:** Record audio from system microphone for speech-to-text.

**Acceptance Criteria:**
- AC-1.1: App can capture audio from the selected input device
- AC-1.2: Recording starts/stops via UI button or global hotkey
- AC-1.3: Audio is sent to the configured STT API endpoint

### FR-2: Speech-to-Text Transcription

**Description:** Send recorded audio to an OpenAI-compatible STT API and display the result.

**Acceptance Criteria:**
- AC-2.1: Audio is sent to a configurable API endpoint with configurable model
- AC-2.2: Transcription result is displayed in the app
- AC-2.3: Supports predefined provider presets (OpenAI, Groq) and custom endpoints

### FR-3: Post-Processing

**Description:** Optionally run transcription through an LLM prompt before output.

**Acceptance Criteria:**
- AC-3.1: Post-processing can be enabled/disabled in settings
- AC-3.2: Configurable prompt templates (fix grammar, summarize, translate, reformat)
- AC-3.3: Uses OpenAI-compatible chat completions API with separate endpoint/key/model config

### FR-4: Text Output

**Description:** Copy result to clipboard or paste directly into the active app.

**Acceptance Criteria:**
- AC-4.1: Result can be copied to clipboard
- AC-4.2: Paste-at-cursor via clipboard sandwich (save clipboard → write text → Cmd+V → restore clipboard)
- AC-4.3: Default output action is configurable (copy, paste, or both)

### FR-5: Sound Feedback

**Description:** Play sounds on recording start, stop, and transcription complete.

**Acceptance Criteria:**
- AC-5.1: Distinct sounds for recording start, stop, and transcription complete
- AC-5.2: Sounds can be enabled/disabled
- AC-5.3: Per-sound volume control

### FR-6: Global Hotkeys

**Description:** Configurable global keyboard shortcuts to control recording.

**Acceptance Criteria:**
- AC-6.1: Configurable global shortcut to start/stop recording
- AC-6.2: Push-to-talk mode (hold to record, release to stop)
- AC-6.3: Toggle mode (press to start, press again to stop)

### FR-7: Menu Bar

**Description:** Menu bar icon with quick-access popover.

**Acceptance Criteria:**
- AC-7.1: Menu bar icon with popover showing status, start/stop, recent transcriptions
- AC-7.2: Icon appearance changes when recording is active
- AC-7.3: Full app window accessible from menu bar

### FR-8: Transcription History

**Description:** List of recent transcriptions with timestamps.

**Acceptance Criteria:**
- AC-8.1: History shows recent transcriptions with timestamps
- AC-8.2: Click to copy any past transcription to clipboard
- AC-8.3: Clear history option

### FR-9: Settings

**Description:** Full settings UI for API configuration, audio, hotkeys, sounds, and output.

**Acceptance Criteria:**
- AC-9.1: API provider presets + custom endpoint URL configuration
- AC-9.2: Per-provider API key storage
- AC-9.3: STT model selection per provider
- AC-9.4: Audio input device selection
- AC-9.5: Hotkey configuration with push-to-talk vs toggle mode choice
- AC-9.6: Sound enable/disable and per-sound volume
- AC-9.7: Default output action selection

## 3. Non-Functional Requirements

### NFR-1: Performance
- Transcription should begin within 1s of recording stop
- UI must remain responsive during recording and API calls

### NFR-2: Security
- API keys stored securely (macOS Keychain or encrypted storage)
- No API keys logged or exposed in UI

### NFR-3: Accessibility
- Standard macOS accessibility support for all UI elements

## 4. Out of Scope

- Local Whisper inference (API-only for now)
- Platforms other than macOS
- Real-time streaming transcription
- Multi-language simultaneous transcription

## 5. Traceability Matrix

| Requirement | Implementation | Tests |
|-------------|---------------|-------|
| AC-1.1      |               |       |
| AC-1.2      |               |       |
| AC-1.3      |               |       |
| AC-2.1      |               |       |
| AC-2.2      |               |       |
| AC-2.3      |               |       |
| AC-3.1      |               |       |
| AC-3.2      |               |       |
| AC-3.3      |               |       |
| AC-4.1      |               |       |
| AC-4.2      |               |       |
| AC-4.3      |               |       |
| AC-5.1      |               |       |
| AC-5.2      |               |       |
| AC-5.3      |               |       |
| AC-6.1      |               |       |
| AC-6.2      |               |       |
| AC-6.3      |               |       |
| AC-7.1      |               |       |
| AC-7.2      |               |       |
| AC-7.3      |               |       |
| AC-8.1      |               |       |
| AC-8.2      |               |       |
| AC-8.3      |               |       |
| AC-9.1      |               |       |
| AC-9.2      |               |       |
| AC-9.3      |               |       |
| AC-9.4      |               |       |
| AC-9.5      |               |       |
| AC-9.6      |               |       |
| AC-9.7      |               |       |
