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
- AC-2.3: Supports predefined provider presets (OpenAI, Groq, xAI, Google Gemini, OpenRouter) and custom endpoints

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
- AC-6.4: Custom hotkey recorder that waits for modifier+key combo (not bare modifiers)
- AC-6.5: Human-readable hotkey display (e.g. "Ctrl + Shift + Space", not hex codes)
- AC-6.6: Correct key code translation between USB HID, Carbon, and display formats

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

### FR-11: End-to-End Integration Tests

**Description:** Full-app integration tests that launch the real app with mocked backends, verifying complete user flows from recording through output.

**Acceptance Criteria:**
- AC-11.1: Happy path E2E — record → transcribe → post-process → output → history entry
- AC-11.2: Error recovery — STT failure shows error, retry succeeds
- AC-11.3: Error recovery — post-processing failure shows error with raw text, retry succeeds
- AC-11.4: Feature toggle — post-processing disabled skips LLM and outputs raw text
- AC-11.5: Settings round-trip — change config (auto-saved), reload, verify persisted
- AC-11.6: History CRUD — create, view, delete, clear all

### FR-12: Structured Logging

**Description:** Integrate the_logger library for structured, level-based logging throughout the app. Console output only — no log viewer or export UI for now.

**Acceptance Criteria:**
- AC-12.1: All key services use Dart `Logger` instances with meaningful logger names
- AC-12.2: API keys and sensitive data are masked in console output via `MaskingString`
- AC-12.3: Existing `print()`/`debugPrint()` calls replaced with appropriate log levels
- AC-12.4: Session starts are logged with app version info
- AC-12.5: Errors and exceptions use `Logger.severe()` with error objects attached

### FR-13: Dynamic Model Discovery

**Description:** Fetch available models from the configured API provider via `GET /v1/models` and present them in a dropdown, replacing the current free-text model field. Applies to both STT and LLM (post-processing) provider sections.

**Acceptance Criteria:**
- AC-13.1: App calls `GET {baseUrl}/v1/models` to fetch model list when a provider is configured with a valid base URL and API key
- AC-13.2: STT model selector shows an autocomplete combo-box (models matching `whisper*` or other STT heuristics as suggestions) with free-text entry always available
- AC-13.3: LLM model selector shows an autocomplete combo-box (chat/completion models as suggestions) with free-text entry always available
- AC-13.4: Model list is refreshed when provider base URL or API key changes
- AC-13.5: Graceful degradation — if `/v1/models` fails (network error, 404, auth error), fall back to the current free-text field with no error blocking the user
- AC-13.6: Loading state shown while fetching models
- AC-13.7: Works with OpenAI, Groq, xAI, Google Gemini, OpenRouter, and custom OpenAI-compatible endpoints (Ollama, LM Studio, vLLM)

### FR-14: DMG Distribution & Homebrew Tap

**Description:** Package the app as a standalone DMG for direct download and as a Homebrew cask for `brew install` distribution. No Apple Developer account or code signing — uses ad-hoc signing and quarantine stripping via Homebrew.

**Acceptance Criteria:**
- AC-14.1: Build script produces a `.dmg` file from `fvm flutter build macos --release` output
- AC-14.2: DMG opens with app icon and Applications folder shortcut (drag-to-install UX)
- AC-14.3: App is ad-hoc signed (`codesign -s -`) to prevent "damaged app" errors
- AC-14.4: DMG can be hosted on GitHub Releases
- AC-14.5: Homebrew tap repository with cask formula pointing to GitHub Release asset
- AC-14.6: `brew install --cask <tap>/duckmouth` installs the app and strips quarantine
- AC-14.7: Build script is documented and runnable in a single command

### FR-15: Model Selection Fix

**Description:** Model selector always allows free-text entry via autocomplete combo-box. Post-processing presets default to LLM models (not STT whisper models).

**Acceptance Criteria:**
- AC-15.1: Model field is always editable (not locked to dropdown) for both STT and PP
- AC-15.2: Fetched models appear as autocomplete suggestions while allowing free typing
- AC-15.3: Groq PP preset defaults to `llama-3.3-70b-versatile` (not `whisper-large-v3-turbo`)
- AC-15.4: Provider presets have separate `model` (STT) and `llmModel` (PP) defaults

### FR-16: Auto-save Settings

**Description:** Settings are persisted immediately on change without requiring a Save button. Text fields use 500ms debounce.

**Acceptance Criteria:**
- AC-16.1: No Save button in settings UI
- AC-16.2: Dropdown/switch/slider changes persist immediately
- AC-16.3: Text field changes persist after 500ms debounce
- AC-16.4: No save loops from cubit state re-emission

### FR-17: Volume Preview Sound

**Description:** When user releases a volume slider, the app plays the corresponding sound at the selected volume level.

**Acceptance Criteria:**
- AC-17.1: Releasing a volume slider plays the matching sound (start/stop/complete) at the selected volume
- AC-17.2: Volume is saved on slider release

### FR-18: Dark Mode Banner Colors

**Description:** Accessibility permission banners use theme-aware colors that are visible in both light and dark modes.

**Acceptance Criteria:**
- AC-18.1: Granted/denied/unknown banners are clearly visible in dark mode
- AC-18.2: Icon colors have proper contrast against banner background in both themes

### FR-19: Model Fetch Diagnostics

**Description:** Show specific error reasons when model list fetch fails, instead of the generic "Could not load models" message. Users need to know whether the problem is an invalid API key, wrong URL, network issue, or unsupported endpoint.

**Acceptance Criteria:**
- AC-19.1: On HTTP error, helper text shows status-specific message (e.g. "401 Unauthorized — check API key", "404 Not Found", "429 Rate Limited")
- AC-19.2: On network/timeout error, helper text shows "Network error — check connection"
- AC-19.3: On malformed response (not JSON, missing `data` field), helper text shows "Unexpected response format"
- AC-19.4: Model field remains fully editable (free-text) regardless of error
- AC-19.5: `ModelsClient.fetchModels` returns a result type carrying either the model list or a specific error message (not just an empty list)

### FR-20: Base URL Path Migration

**Description:** Move the `/v1` path segment from hardcoded API client code into provider base URLs. This enables providers with non-standard version paths (e.g. Google Gemini's `/v1beta/openai`) to work without special-casing.

**Acceptance Criteria:**
- AC-20.1: API clients (`OpenAiClient`, `LlmClient`, `ModelsClient`) append `/models`, `/audio/transcriptions`, `/chat/completions` directly to `baseUrl` without inserting `/v1/`
- AC-20.2: All provider preset base URLs include the version path segment (OpenAI → `https://api.openai.com/v1`, Groq → `https://api.groq.com/openai/v1`)
- AC-20.3: Existing saved settings migrated on load — if a saved base URL matches a known old-format value (e.g. `https://api.openai.com`), `/v1` is appended automatically
- AC-20.4: Custom provider users can enter any base URL path
- AC-20.5: All existing STT, LLM, and model-fetch functionality works unchanged after migration

### FR-21: Additional Provider Presets

**Description:** Add provider presets for xAI (Grok), Google Gemini, and OpenRouter alongside existing OpenAI and Groq presets. Since models are fetched dynamically via `/v1/models`, default model names serve only as initial suggestions.

**Acceptance Criteria:**
- AC-21.1: xAI preset with base URL `https://api.x.ai/v1`, no default STT model, default LLM `grok-4-1-fast-non-reasoning`
- AC-21.2: Google Gemini preset with base URL `https://generativelanguage.googleapis.com/v1beta/openai`, no default STT model, default LLM `gemini-3-flash`
- AC-21.3: OpenRouter preset with base URL `https://openrouter.ai/api/v1`, no default STT model, default LLM `openrouter/auto`
- AC-21.4: Provider dropdown shows all presets (OpenAI, Groq, xAI, Gemini, OpenRouter, Custom) in both STT and PP sections
- AC-21.5: Selecting a provider with no default STT model shows hint text "This provider has no STT models" in the STT model field
- AC-21.6: Model fetch (`/models` endpoint) works for all new providers and populates the dropdown dynamically
- AC-21.7: STT and LLM API calls work with each provider that supports them

### FR-22: In-App Log Viewer

**Description:** Embed an in-app log viewer using the `the_logger_viewer_widget` package, accessible as a dedicated nav item from the home page AppBar. Requires upgrading `the_logger` to `^0.0.20` (pub.dev) for streaming support.

**Acceptance Criteria:**
- AC-22.1: `the_logger` dependency changed from path to pub.dev `^0.0.20`
- AC-22.2: `the_logger_viewer_widget` added as pub.dev dependency `^0.0.2`
- AC-22.3: "Logs" icon button in home AppBar opens a full-screen log viewer page
- AC-22.4: Log viewer shows real-time streaming log updates
- AC-22.5: Log viewer supports filtering by level, search text, and logger name
- AC-22.6: Log viewer supports session navigation
- AC-22.7: Log viewer available in both debug and release builds

### FR-23: Trailing Space on Text Insertion

**Description:** Append a trailing space to text when inserting at the cursor, so the user can continue typing immediately without manually adding a space.

**Acceptance Criteria:**
- AC-23.1: Text inserted via `pasteAtCursor` has a trailing space appended
- AC-23.2: Text copied to clipboard (without paste) is NOT modified — trailing space only applies to cursor insertion
- AC-23.3: If text already ends with whitespace, no extra space is added

### FR-24: Custom App & Tray Icons

**Description:** Replace the default Flutter icon with a custom Duckmouth icon for the app icon and menu bar tray icon. Icon artwork is generated externally (Nano Banana) from a prompt stored in the repo.

**Acceptance Criteria:**
- AC-24.1: App icon shows a custom Duckmouth duck icon (not the Flutter logo) at all required macOS sizes (16, 32, 64, 128, 256, 512, 1024px)
- AC-24.2: Menu bar tray icon shows a custom monochrome duck silhouette (not the Flutter arrow) as a macOS template image (~18x18px)
- AC-24.3: Icon generation prompts are stored in `specs/icon-prompts.md` for reproducibility
- AC-24.4: DMG background/branding uses the new icon (if build script references it)

### FR-25: Hotkey Rapid Press Race Condition Fix

**Description:** Fix a race condition where pressing and releasing the global hotkey very quickly causes the app to get stuck in "recording" state. The stop command arrives before the async start has completed, leaving the recorder running with no way to stop it.

**Acceptance Criteria:**
- AC-25.1: Rapid press-and-release of push-to-talk hotkey does not leave the app stuck in recording state
- AC-25.2: If `stopRecording()` is called while `startRecording()` is still in progress, the recording is stopped as soon as start completes
- AC-25.3: Rapid toggling in toggle mode does not produce inconsistent state

### FR-26: Theme Selection

**Description:** Add a theme mode selector to settings: System (follow OS), Dark, Light.

**Acceptance Criteria:**
- AC-26.1: Settings page has a theme mode dropdown with System, Dark, Light options
- AC-26.2: Selecting Dark/Light applies the theme immediately
- AC-26.3: System mode follows macOS appearance (current default behavior)
- AC-26.4: Theme preference persisted via SharedPreferences
- AC-26.5: Default is System (preserves current behavior)

## 4. Out of Scope

- Local Whisper inference (API-only for now)
- Platforms other than macOS
- Real-time streaming transcription
- Multi-language simultaneous transcription
- Apple Developer account / code signing / notarization (can be added later)

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
| AC-6.4      | `lib/features/hotkey/ui/hotkey_recorder_dialog.dart` | `test/features/hotkey/ui/hotkey_recorder_dialog_test.dart` |
| AC-6.5      | `lib/features/hotkey/domain/hotkey_config.dart` | `test/features/hotkey/domain/hotkey_config_test.dart` |
| AC-6.6      | `lib/features/hotkey/domain/key_code_translator.dart` | `test/features/hotkey/domain/key_code_translator_test.dart` |
| AC-7.1      | `lib/app/system_tray_manager.dart` | `test/app/app_test.dart` |
| AC-7.2      | `lib/app/home_page.dart` | `test/app/home_page_integration_test.dart` |
| AC-7.3      | `lib/app/system_tray_manager.dart` | `test/app/app_test.dart` |
| AC-8.1      | `lib/features/history/ui/history_page.dart` | `test/features/history/ui/history_cubit_test.dart` |
| AC-8.2      | `lib/features/history/ui/history_page.dart` | `test/features/history/ui/history_cubit_test.dart` |
| AC-8.3      | `lib/features/history/ui/history_page.dart` | `test/features/history/ui/history_cubit_test.dart` |
| AC-9.1      | `lib/features/settings/domain/provider_preset.dart`, `lib/features/settings/ui/settings_page.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-9.2      | `lib/features/settings/data/settings_repository_impl.dart` (SharedPreferences) | `test/features/settings/data/settings_repository_impl_test.dart` |
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
| AC-11.1     | `integration_test/app_test.dart` | `integration_test/app_test.dart` |
| AC-11.2     | `integration_test/app_test.dart` | `integration_test/app_test.dart` |
| AC-11.3     | `integration_test/app_test.dart` | `integration_test/app_test.dart` |
| AC-11.4     | `integration_test/app_test.dart` | `integration_test/app_test.dart` |
| AC-11.5     | `integration_test/settings_test.dart` | `integration_test/settings_test.dart` |
| AC-11.6     | `integration_test/history_test.dart` | `integration_test/history_test.dart` |
| AC-12.1     | `lib/` (Logger instances in services, cubits, repositories) | `test/core/logging/logging_setup_test.dart` |
| AC-12.2     | `lib/core/logging/logging_setup.dart` (masking config) | `test/core/logging/logging_setup_test.dart` |
| AC-12.3     | `lib/` (replacement of print/debugPrint calls) | `test/core/logging/logging_setup_test.dart` |
| AC-12.4     | `lib/core/logging/logging_setup.dart` (sessionStartExtra) | `test/core/logging/logging_setup_test.dart` |
| AC-12.5     | `lib/` (Logger.severe calls in catch blocks) | `test/core/logging/logging_setup_test.dart` |
| AC-13.1     | `lib/core/api/models_client.dart` | `test/core/api/models_client_test.dart` |
| AC-13.2     | `lib/features/settings/ui/settings_page.dart`, `lib/features/settings/ui/model_dropdown.dart` | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-13.3     | `lib/features/settings/ui/settings_page.dart`, `lib/features/settings/ui/model_dropdown.dart` | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-13.4     | `lib/features/settings/ui/settings_cubit.dart` | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-13.5     | `lib/features/settings/ui/model_dropdown.dart` | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-13.6     | `lib/features/settings/ui/model_dropdown.dart` | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-13.7     | `lib/core/api/models_client.dart` | `test/core/api/models_client_test.dart` |
| AC-14.1     | `scripts/build_dmg.sh` | Manual verification |
| AC-14.2     | `scripts/build_dmg.sh` (create-dmg config) | Manual verification |
| AC-14.3     | `scripts/build_dmg.sh` (codesign -s -) | Manual verification |
| AC-14.4     | GitHub Releases (manual or CI) | Manual verification |
| AC-14.5     | `homebrew-duckmouth/Casks/duckmouth.rb` (separate repo) | `brew audit --cask duckmouth` |
| AC-14.6     | Homebrew cask formula | Manual verification |
| AC-14.7     | `scripts/build_dmg.sh`, `README` section | Manual verification |
| AC-15.1     | `lib/features/settings/ui/settings_page.dart` (enabled: true for model dropdowns) | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-15.2     | `lib/features/settings/ui/model_dropdown.dart` (RawAutocomplete) | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-15.3     | `lib/features/settings/ui/settings_page.dart` (`_onPpPresetChanged` uses `preset.llmModel`) | `test/features/settings/domain/provider_preset_test.dart` |
| AC-15.4     | `lib/features/settings/domain/provider_preset.dart` (`llmModel` field) | `test/features/settings/domain/provider_preset_test.dart` |
| AC-16.1     | `lib/features/settings/ui/settings_page.dart` (Save button removed) | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-16.2     | `lib/features/settings/ui/settings_page.dart` (immediate save in onChanged) | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-16.3     | `lib/features/settings/ui/settings_page.dart` (_debounce with 500ms timer) | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-16.4     | `lib/features/settings/ui/settings_page.dart` (_setTextIfDifferent guard) | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-17.1     | `lib/features/settings/ui/settings_page.dart` (_VolumeSlider.onChangeEnd) | `test/core/services/sound_service_test.dart` |
| AC-17.2     | `lib/features/settings/ui/settings_page.dart` (_saveSoundConfig in onChangeEnd) | `test/features/settings/ui/settings_cubit_test.dart` |
| AC-18.1     | `lib/features/settings/ui/settings_page.dart`, `lib/app/home_page.dart` (isDark color branching) | Manual verification |
| AC-18.2     | `lib/features/settings/ui/settings_page.dart`, `lib/app/home_page.dart` (explicit iconColor) | Manual verification |
| AC-19.1     | `lib/core/api/models_client.dart`, `lib/features/settings/ui/model_dropdown.dart` | `test/core/api/models_client_test.dart`, `test/features/settings/ui/model_dropdown_test.dart` |
| AC-19.2     | `lib/core/api/models_client.dart`, `lib/features/settings/ui/model_dropdown.dart` | `test/core/api/models_client_test.dart`, `test/features/settings/ui/model_dropdown_test.dart` |
| AC-19.3     | `lib/core/api/models_client.dart`, `lib/features/settings/ui/model_dropdown.dart` | `test/core/api/models_client_test.dart`, `test/features/settings/ui/model_dropdown_test.dart` |
| AC-19.4     | `lib/features/settings/ui/model_dropdown.dart` | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-19.5     | `lib/core/api/models_client.dart` | `test/core/api/models_client_test.dart` |
| AC-20.1     | `lib/core/api/openai_client.dart`, `lib/core/api/llm_client.dart`, `lib/core/api/models_client.dart` | `test/core/api/openai_client_test.dart`, `test/core/api/llm_client_test.dart`, `test/core/api/models_client_test.dart` |
| AC-20.2     | `lib/features/settings/domain/provider_preset.dart` | `test/features/settings/domain/provider_preset_test.dart` |
| AC-20.3     | `lib/features/settings/data/settings_repository_impl.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-20.4     | `lib/features/settings/ui/settings_page.dart` | `test/features/settings/ui/settings_page_test.dart` |
| AC-20.5     | All API clients | All API client tests |
| AC-21.1     | `lib/features/settings/domain/provider_preset.dart` | `test/features/settings/domain/provider_preset_test.dart` |
| AC-21.2     | `lib/features/settings/domain/provider_preset.dart` | `test/features/settings/domain/provider_preset_test.dart` |
| AC-21.3     | `lib/features/settings/domain/provider_preset.dart` | `test/features/settings/domain/provider_preset_test.dart` |
| AC-21.4     | `lib/features/settings/ui/settings_page.dart` | `test/features/settings/ui/settings_page_test.dart` |
| AC-21.5     | `lib/features/settings/ui/model_dropdown.dart` | `test/features/settings/ui/model_dropdown_test.dart` |
| AC-21.6     | `lib/core/api/models_client.dart` | `test/core/api/models_client_test.dart` |
| AC-21.7     | `lib/core/api/openai_client.dart`, `lib/core/api/llm_client.dart` | `test/core/api/openai_client_test.dart`, `test/core/api/llm_client_test.dart` |
| AC-22.1     | `pubspec.yaml` (`the_logger: ^0.0.20`) | `fvm flutter pub get` succeeds |
| AC-22.2     | `pubspec.yaml` (`the_logger_viewer_widget: ^0.0.2`) | `fvm flutter pub get` succeeds |
| AC-22.3     | `lib/app/home_page.dart` (`_LogsButton`) | `test/app/home_page_test.dart` |
| AC-22.4     | `TheLoggerViewerWidget` (provided by package) | `test/app/home_page_test.dart` |
| AC-22.5     | `TheLoggerViewerWidget` (provided by package) | Package tests |
| AC-22.6     | `TheLoggerViewerWidget` (provided by package) | Package tests |
| AC-22.7     | No conditional imports or `kDebugMode` guards | Manual verification |
| AC-23.1     | `lib/core/services/clipboard_service.dart` (`pasteAtCursor`) | `test/core/services/clipboard_service_test.dart` |
| AC-23.2     | `lib/core/services/clipboard_service.dart` (`copyToClipboard` unchanged) | `test/core/services/clipboard_service_test.dart` |
| AC-23.3     | `lib/core/services/clipboard_service.dart` (whitespace guard) | `test/core/services/clipboard_service_test.dart` |
| AC-24.1     | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` | Manual verification |
| AC-24.2     | `assets/tray_icon.png` | Manual verification |
| AC-24.3     | `specs/icon-prompts.md` | File exists with prompts |
| AC-24.4     | `scripts/build_dmg.sh` (if applicable) | Manual verification |
| AC-25.1     | `lib/features/recording/ui/recording_cubit.dart` | `test/features/recording/ui/recording_cubit_test.dart` |
| AC-25.2     | `lib/features/recording/ui/recording_cubit.dart` (`_pendingStop`) | `test/features/recording/ui/recording_cubit_test.dart` |
| AC-25.3     | `lib/features/recording/ui/recording_cubit.dart` | `test/features/recording/ui/recording_cubit_test.dart` |
| AC-26.1     | `lib/features/settings/ui/settings_page.dart` | `test/features/settings/ui/settings_page_test.dart` |
| AC-26.2     | `lib/app/app.dart` (`BlocBuilder<SettingsCubit>`) | `test/app/app_test.dart` |
| AC-26.3     | `lib/app/app.dart` (`ThemeMode.system` default) | `test/app/app_test.dart` |
| AC-26.4     | `lib/features/settings/data/settings_repository_impl.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
| AC-26.5     | `lib/features/settings/data/settings_repository_impl.dart` | `test/features/settings/data/settings_repository_impl_test.dart` |
