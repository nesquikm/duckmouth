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
- AC-4.2: Paste-at-cursor via Accessibility API with clipboard sandwich fallback (see FR-10)
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

### FR-10: Accessibility API Text Insertion

**Description:** Use macOS Accessibility API to insert text directly at the cursor in other apps, avoiding clipboard clobbering. Fall back to clipboard sandwich when the target app doesn't support AX text insertion.

**Acceptance Criteria:**
- AC-10.1: Text inserted at cursor via Accessibility API (`kAXSelectedTextAttribute`) in supported apps
- AC-10.2: Automatic fallback to CGEvent Cmd+V (clipboard sandwich) when AX insert fails
- AC-10.3: Final fallback to osascript preserves existing behavior
- AC-10.4: App checks Accessibility permission status and prompts user to grant it
- AC-10.5: Permission status displayed in settings page

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
| AC-1.1      | `lib/features/recording/data/recording_repository_impl.dart` | `test/features/recording/data/recording_repository_impl_test.dart` |
| AC-1.2      | `lib/features/recording/ui/recording_controls.dart`, `lib/features/hotkey/ui/hotkey_cubit.dart` | `test/features/recording/ui/recording_controls_test.dart`, `test/features/hotkey/ui/hotkey_cubit_test.dart` |
| AC-1.3      | `lib/features/transcription/data/stt_repository_impl.dart`, `lib/core/api/openai_client.dart` | `test/core/api/openai_client_test.dart` |
| AC-2.1      | `lib/core/api/openai_client.dart`, `lib/features/settings/domain/api_config.dart` | `test/core/api/openai_client_test.dart` |
| AC-2.2      | `lib/features/transcription/ui/transcription_display.dart`, `lib/features/transcription/ui/transcription_cubit.dart` | `test/features/transcription/ui/transcription_cubit_test.dart` |
| AC-2.3      | `lib/features/settings/domain/provider_preset.dart`, `lib/features/settings/ui/settings_page.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-3.1      | `lib/features/post_processing/domain/post_processing_config.dart`, `lib/features/settings/ui/settings_page.dart` | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-3.2      | `lib/features/post_processing/domain/post_processing_config.dart` (`PromptTemplate` enum), `lib/features/settings/ui/settings_page.dart` | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-3.3      | `lib/core/api/llm_client.dart`, `lib/features/post_processing/data/post_processing_repository_impl.dart` | `test/core/api/llm_client_test.dart` |
| AC-4.1      | `lib/core/services/clipboard_service.dart`, `lib/app/home_page.dart` | `test/core/services/clipboard_service_test.dart` |
| AC-4.2      | `lib/core/services/accessibility_service.dart`, `macos/Runner/TextInsertionChannel.swift` | `test/core/services/accessibility_service_test.dart` |
| AC-4.3      | `lib/core/services/output_mode.dart`, `lib/features/settings/ui/settings_page.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-5.1      | `lib/core/services/sound_service.dart`, `macos/Runner/SoundChannel.swift` | `test/core/services/sound_service_test.dart` |
| AC-5.2      | `lib/core/services/sound_config.dart`, `lib/features/settings/ui/settings_page.dart` | `test/core/services/sound_service_test.dart` |
| AC-5.3      | `lib/core/services/sound_config.dart`, `lib/features/settings/ui/settings_page.dart` | `test/core/services/sound_service_test.dart` |
| AC-6.1      | `lib/features/hotkey/domain/hotkey_config.dart`, `lib/features/hotkey/ui/hotkey_cubit.dart` | `test/features/hotkey/ui/hotkey_cubit_test.dart` |
| AC-6.2      | `lib/features/hotkey/ui/hotkey_cubit.dart` | `test/features/hotkey/ui/hotkey_cubit_test.dart` |
| AC-6.3      | `lib/features/hotkey/ui/hotkey_cubit.dart` | `test/features/hotkey/ui/hotkey_cubit_test.dart` |
| AC-7.1      | `lib/app/system_tray_manager.dart` | `test/app/app_test.dart` |
| AC-7.2      | `lib/app/home_page.dart` | `test/app/home_page_integration_test.dart` |
| AC-7.3      | `lib/app/system_tray_manager.dart` | `test/app/app_test.dart` |
| AC-8.1      | `lib/features/history/ui/history_page.dart` | `test/features/history/ui/history_cubit_test.dart` |
| AC-8.2      | `lib/features/history/ui/history_page.dart` | `test/features/history/ui/history_cubit_test.dart` |
| AC-8.3      | `lib/features/history/ui/history_page.dart` | `test/features/history/ui/history_cubit_test.dart` |
| AC-9.1      | `lib/features/settings/domain/provider_preset.dart`, `lib/features/settings/ui/settings_page.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-9.2      | `lib/features/settings/data/settings_repository_impl.dart` (FlutterSecureStorage) | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-9.3      | `lib/features/settings/ui/settings_page.dart`, `lib/features/settings/domain/provider_preset.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-9.4      | `lib/features/settings/ui/settings_page.dart`, `lib/features/recording/data/recording_repository_impl.dart` | `test/features/settings/data/settings_repository_impl_test.dart`, `test/features/settings/ui/settings_cubit_test.dart` |
| AC-9.5      | `lib/features/settings/ui/settings_page.dart`, `lib/features/hotkey/domain/hotkey_config.dart` | `test/features/hotkey/domain/hotkey_config_test.dart` |
| AC-9.6      | `lib/features/settings/ui/settings_page.dart`, `lib/core/services/sound_config.dart` | `test/core/services/sound_service_test.dart` |
| AC-9.7      | `lib/features/settings/ui/settings_page.dart`, `lib/core/services/output_mode.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-10.1     | `lib/core/services/accessibility_service.dart`, `macos/Runner/TextInsertionChannel.swift` | `test/core/services/accessibility_service_test.dart` |
| AC-10.2     | `lib/core/services/accessibility_service.dart` | `test/core/services/accessibility_service_test.dart` |
| AC-10.3     | `lib/core/services/accessibility_service.dart` | `test/core/services/accessibility_service_test.dart` |
| AC-10.4     | `macos/Runner/TextInsertionChannel.swift`, `lib/features/settings/ui/settings_cubit.dart` | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-10.5     | `lib/features/settings/ui/settings_page.dart`, `lib/features/settings/ui/settings_state.dart` | `test/features/settings/ui/settings_cubit_test.dart` |
