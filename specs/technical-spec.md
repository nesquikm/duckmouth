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
│   ├── logging/                  # TheLogger setup and masking config
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
| Global hotkeys | hotkey_manager plugin + custom recorder | Native registration via hotkey_manager; custom recorder dialog replaces broken HotKeyRecorder widget |
| Audio recording | record plugin | Mature, supports macOS audio capture; encodes WAV, FLAC, AAC, Opus natively |
| Audio default format | WAV 16kHz 16-bit mono | Maximum compatibility — works with all backends including whisper.cpp. Whisper resamples to 16kHz mono internally, so higher quality is wasted |
| Secure storage | SharedPreferences | API keys stored locally (Keychain requires code signing entitlements) |
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

### Models API (OpenAI-compatible)
- `GET /v1/models`
- Response: `{ "object": "list", "data": [{ "id": "model-name", "object": "model", "created": 1686935002, "owned_by": "owner" }, ...] }`
- No server-side filtering — client filters by model ID heuristics:
  - **STT models:** ID contains `whisper` (case-insensitive)
  - **LLM models:** all models not matching STT/embedding/tts/image patterns
- Endpoint is widely supported: OpenAI, Groq, Ollama, vLLM, LM Studio, OpenRouter

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

### Hotkey Key Code Translation

The hotkey system involves three different key code formats that must be translated between each other:

| Format | Example (Space) | Used By |
|--------|----------------|---------|
| USB HID usage code | `0x0007002C` | Flutter `PhysicalKeyboardKey`, duckmouth persistence |
| Carbon key code | `49` (`kVK_Space`) | macOS native `HotKey` Swift library, `hotkey_manager_macos` plugin |
| Display label | `"Space"` | Settings UI |

**Key code translator** (`lib/features/hotkey/domain/key_code_translator.dart`):
- `usbHidToCarbon(int usbHid) → int?` — converts USB HID to Carbon for native registration
- `usbHidToLabel(int usbHid) → String` — converts USB HID to human-readable label
- Uses `kMacOsToPhysicalKey` map from `uni_platform` extension for USB HID ↔ Carbon mapping

**Custom hotkey recorder** (`lib/features/hotkey/ui/hotkey_recorder_dialog.dart`):
- Replaces `hotkey_manager`'s broken `HotKeyRecorder` widget
- Uses `RawKeyboardListener` / `HardwareKeyboard` to capture key events
- Waits for a non-modifier key after modifiers are pressed (doesn't fire on bare modifiers)
- Displays the combo as it's built (e.g., "Ctrl + ..." → "Ctrl + Shift + Space")

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
- E2E integration tests: full app with fake backends via `integration_test/`
- No real API calls in tests

### E2E Test Architecture
- `IntegrationTestWidgetsFlutterBinding` launches the real app widget tree
- GetIt service locator overridden with fake implementations before app launch
- Fakes implement production interfaces (e.g., `FakeSttRepository implements SttRepository`)
- Fakes are deterministic (canned responses, configurable errors) — no `when()` setup
- Platform services (sound, accessibility, hotkeys) replaced with no-op fakes
- Run via `fvm flutter test integration_test/`

## 5. Logging

### Library

[the_logger](https://pub.dev/packages/the_logger) — a wrapper around Dart's `logging` package that adds colorful console output, sensitive data masking, and session-based organization.

**Path dependency:** `~/workspace/the/the_logger` (local development)

### Initialization

```dart
// lib/core/logging/logging_setup.dart
import 'package:the_logger/the_logger.dart';
import 'package:logging/logging.dart';

Future<void> setupLogging() async {
  await TheLogger.i().init(
    dbLogger: false,           // no SQLite — console only
    consoleLogger: true,       // ANSI-colored console output
    consoleFormatJson: true,   // pretty-print JSON in log messages
    sessionStartExtra: appVersion,  // include app version in session start
  );
}
```

Called in `main()` before `runApp()`.

### Logger Usage

Each class creates its own named `Logger` instance:

```dart
final _log = Logger('RecordingRepositoryImpl');

// Levels:
_log.fine('Starting recording with device: $deviceId');   // debug detail
_log.info('Recording started');                           // normal operation
_log.warning('Fallback to default input device');         // recoverable issue
_log.severe('Recording failed', error, stackTrace);       // error
```

### Sensitive Data Masking

API keys are masked before they reach the console:

```dart
TheLogger.i().addMaskingString(
  MaskingString(apiKey, maskedString: '***API_KEY***'),
);
```

Masking strings are added/removed in `SettingsCubit` when API keys change.

### Log Levels by Context

| Context | Level | Example |
|---------|-------|---------|
| State transitions | `fine` | "RecordingState: idle → recording" |
| Normal operations | `info` | "Transcription complete, 42 words" |
| Recoverable issues | `warning` | "AX insert failed, falling back to CGEvent" |
| Errors | `severe` | "STT API returned 401" (with error object) |
| Detailed debugging | `finest` | HTTP request/response bodies |

## 6. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | latest | BLoC/Cubit state management |
| bloc | 9.2.0 | BLoC core |
| equatable | latest | Value equality for states |
| http | latest | HTTP client for API calls |
| record | latest | Audio recording |
| system_tray | latest | Menu bar integration |
| hotkey_manager | latest | Global hotkey registration |
| flutter_secure_storage | latest | (deprecated — replaced by SharedPreferences for API keys) |
| shared_preferences | latest | Non-sensitive settings persistence |
| uuid | latest | Unique IDs for history entries |
| path_provider | latest | App data directory |
| the_logger | path | Structured logging with console output, masking, sessions |
| logging | latest | Dart standard logging (peer dependency of the_logger) |
| mocktail | 1.0.4 | Test mocking (dev) |
| bloc_test | 10.0.0 | BLoC testing (dev) |
