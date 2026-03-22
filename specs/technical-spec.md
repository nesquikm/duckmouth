# Technical Specification

## 1. Architecture

### System Overview

Duckmouth is a Flutter macOS app using BLoC/Cubit for state management and a feature-first directory structure. It communicates with external OpenAI-compatible APIs for STT and LLM post-processing. Native macOS features (menu bar, global hotkeys, clipboard, audio input) are accessed via platform channels or Flutter plugins.

### Directory Structure

```
lib/
├── app/                          # App widget, routing, theme
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── features/
│   ├── recording/                # Audio capture
│   │   ├── data/                 # Audio recorder implementation
│   │   ├── domain/               # Recording state, audio config model
│   │   └── ui/                   # Recording controls, status indicator
│   ├── transcription/            # STT + post-processing
│   │   ├── data/                 # STT API client, LLM API client
│   │   ├── domain/               # Transcription model, API config
│   │   └── ui/                   # Transcription display, cubit
│   ├── history/                  # Transcription history
│   │   ├── data/                 # Local storage repository
│   │   ├── domain/               # History entry model
│   │   └── ui/                   # History list, cubit
│   ├── settings/                 # App settings
│   │   ├── data/                 # Settings repository (SharedPreferences + Keychain)
│   │   ├── domain/               # Settings model
│   │   └── ui/                   # Settings screens, cubit
│   ├── hotkeys/                  # Global hotkey management
│   │   ├── data/                 # Hotkey registration
│   │   ├── domain/               # Hotkey config model
│   │   └── ui/                   # Hotkey config widget
│   ├── menubar/                  # Menu bar + popover
│   │   └── ui/                   # System tray, popover widget
│   └── output/                   # Clipboard + paste-at-cursor
│       ├── data/                 # Clipboard service, paste service
│       └── domain/               # Output config model
├── core/
│   ├── api/                      # HTTP client, OpenAI-compatible base
│   ├── audio/                    # Audio format utilities
│   ├── di/                       # Dependency injection setup
│   ├── extensions/               # Dart extensions
│   └── constants.dart
└── main.dart
test/                             # Mirrors lib/ structure
macos/                            # Native macOS runner
specs/                            # SDD spec files
```

### Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | Flutter 3.41.5 | Cross-platform potential, rich plugin ecosystem |
| State management | BLoC/Cubit | Predictable, testable state; bloc_test support |
| API abstraction | OpenAI-compatible | Single client for multiple providers (OpenAI, Groq, custom) |
| Directory structure | Feature-first | Scales well, clear module boundaries |
| Menu bar | system_tray or tray_manager plugin | Native macOS system tray integration |
| Global hotkeys | hotkey_manager plugin | Cross-platform hotkey registration |
| Audio recording | record plugin | Mature, supports macOS audio capture; encodes WAV, FLAC, AAC, Opus natively |
| Audio default format | WAV 16kHz 16-bit mono | Maximum compatibility — works with all backends including whisper.cpp. Whisper resamples to 16kHz mono internally, so higher quality is wasted |
| Secure storage | flutter_secure_storage | macOS Keychain for API keys |
| Text insertion | Native Swift platform channel | AX API direct insert with CGEvent fallback — avoids clipboard sandwich when possible |

## 2. Data Model

### TranscriptionEntry
- `id`: String (UUID)
- `text`: String (final transcription)
- `rawText`: String (before post-processing)
- `timestamp`: DateTime
- `duration`: Duration (recording length)
- `provider`: String (API provider used)

### ApiConfig
- `endpoint`: String (base URL)
- `apiKey`: String (stored in Keychain)
- `model`: String
- `providerPreset`: ProviderPreset? (OpenAI, Groq, custom)

### RecordingState
- `status`: RecordingStatus (idle, recording, processing)
- `duration`: Duration (current recording length)
- `inputDevice`: AudioDevice?

### AudioFormatConfig
- `format`: AudioFormat (wav, flac, aac, opus)
- `sampleRate`: int (default: 16000 — Whisper resamples to 16kHz internally)
- `channels`: int (default: 1 — mono, stereo adds size with no transcription benefit)
- `bitRate`: int? (for lossy formats: 32000 or 64000)
- `qualityPreset`: QualityPreset (bestCompatibility, balanced, smallest)

### QualityPreset
- `bestCompatibility`: WAV 16kHz 16-bit mono — works with all backends including whisper.cpp
- `balanced`: AAC 64kbps 16kHz mono — 8x smaller, no accuracy loss on cloud APIs
- `smallest`: AAC 32kbps 16kHz mono — minimum viable quality for transcription

### PromptTemplate
- `fixGrammar`: Fix grammar and spelling errors
- `summarize`: Condense into key points
- `translate`: Translate to English
- `reformat`: Clean up structure and punctuation
- `custom`: User-defined prompt

### AccessibilityPermission
- `status`: AccessibilityStatus (granted, denied, unknown)

### AppSettings
- `sttConfig`: ApiConfig
- `llmConfig`: ApiConfig
- `postProcessingEnabled`: bool
- `postProcessingPrompt`: String
- `hotkeyConfig`: HotkeyConfig
- `audioFormatConfig`: AudioFormatConfig
- `outputMode`: OutputMode (copy, paste, both)
- `soundsEnabled`: bool
- `soundVolumes`: Map<SoundEvent, double>
- `selectedInputDevice`: String?

## 3. API / Interface Design

### STT API (OpenAI-compatible)
- `POST /v1/audio/transcriptions`
- Body: multipart form with audio file, model name
- Response: `{ "text": "transcribed text" }`

### LLM Post-Processing API (OpenAI-compatible)
- `POST /v1/chat/completions`
- Body: messages array with system prompt + transcription
- Response: standard chat completions response

### Sound Platform Channel (macOS native)

**Channel name:** `com.duckmouth/sound`

**Methods:**
- `play(name: String, volume: double)` → plays the named macOS system sound via `NSSound(named:)` with the given volume (0.0–1.0). Returns `{ "success": true }` or `{ "success": false, "error": "..." }`

**Native implementation:** `macos/Runner/SoundChannel.swift`

**Notes:**
- `NSSound(named: "Tink")` resolves system sounds from `/System/Library/Sounds/` automatically
- Volume set via `NSSound.volume` property before calling `play()`
- Works in sandboxed apps (unlike `afplay` via `Process.run`)
- Replaces the M8 `afplay`-based implementation

### Text Insertion Platform Channel (macOS native)

**Channel name:** `com.duckmouth/text_insertion`

**Methods:**
- `checkAccessibilityPermission` → `{ "status": "granted" | "denied" | "unknown" }`
- `requestAccessibilityPermission` → opens System Settings prompt via `AXIsProcessTrustedWithOptions`
- `insertTextViaAccessibility(text: String)` → attempts `AXUIElementSetAttributeValue` with `kAXSelectedTextAttribute` on the focused element. Returns `{ "success": true }` or `{ "success": false, "error": "..." }`
- `pasteViaCGEvent(text: String)` → sets clipboard, posts CGEvent Cmd+V key down/up, restores clipboard. Returns `{ "success": true }`

**Native implementation:** `macos/Runner/TextInsertionChannel.swift`

**Fallback chain (in AccessibilityService):**
1. `insertTextViaAccessibility` — no clipboard touch
2. `pasteViaCGEvent` — clipboard sandwich but no subprocess
3. `Process.run('osascript', ...)` — legacy Dart fallback

## 4. Key Patterns

### State Management
- One Cubit per feature screen
- Repository interfaces in `domain/`, implementations in `data/`
- BlocProvider at feature root, BlocBuilder/BlocListener in UI

### Error Handling
- Result type or sealed classes for API responses
- User-facing error messages in UI, detailed logs for debugging
- Graceful degradation: if post-processing fails, show raw transcription

### Testing Strategy
- Unit tests: cubits, repositories, models
- Widget tests: key UI components
- Integration tests: API client with mocked HTTP
- No real API calls in tests

## 5. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | latest | BLoC/Cubit state management |
| bloc | 9.2.0 | BLoC core |
| equatable | latest | Value equality for states |
| http | latest | HTTP client for API calls |
| record | latest | Audio recording |
| system_tray | latest | Menu bar integration |
| hotkey_manager | latest | Global hotkey registration |
| flutter_secure_storage | latest | Secure API key storage (Keychain) |
| shared_preferences | latest | Non-sensitive settings persistence |
| uuid | latest | Unique IDs for history entries |
| path_provider | latest | App data directory |
| mocktail | 1.0.4 | Test mocking (dev) |
| bloc_test | 10.0.0 | BLoC testing (dev) |
