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
| API abstraction | OpenAI-compatible | Single client for multiple providers (OpenAI, Groq, xAI, Google Gemini, OpenRouter, custom) |
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

### ProviderPreset
- `label`: String (display name)
- `baseUrl`: String (API base URL, including version path — clients append `/models`, `/audio/transcriptions`, `/chat/completions` directly)
- `model`: String (default STT model; empty if provider has no STT)
- `llmModel`: String (default LLM model for post-processing)
- Values:
  - `openAi`: baseUrl `https://api.openai.com/v1`, model `whisper-1`, llmModel `gpt-5.4-mini`
  - `groq`: baseUrl `https://api.groq.com/openai/v1`, model `whisper-large-v3-turbo`, llmModel `llama-3.3-70b-versatile`
  - `xAi`: baseUrl `https://api.x.ai/v1`, model `""` (no STT), llmModel `grok-4-1-fast-non-reasoning`
  - `googleGemini`: baseUrl `https://generativelanguage.googleapis.com/v1beta/openai`, model `""` (no STT), llmModel `gemini-3-flash`
  - `openRouter`: baseUrl `https://openrouter.ai/api/v1`, model `""` (no STT), llmModel `openrouter/auto`
  - `custom`: baseUrl `""`, model `""`, llmModel `""`

### ApiConfig
- `endpoint`: String (base URL)
- `apiKey`: String (stored in Keychain)
- `model`: String
- `providerPreset`: ProviderPreset? (OpenAI, Groq, xAI, Google Gemini, OpenRouter, custom)

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
- `POST {baseUrl}/audio/transcriptions`
- Body: multipart form with audio file, model name
- Response: `{ "text": "transcribed text" }`
- Supported by: OpenAI, Groq. Not supported by: xAI, Google Gemini, OpenRouter.

### LLM Post-Processing API (OpenAI-compatible)
- `POST {baseUrl}/chat/completions`
- Body: messages array with system prompt + transcription
- Response: standard chat completions response
- Supported by: all providers (OpenAI, Groq, xAI, Google Gemini, OpenRouter)

### Models API (OpenAI-compatible)
- `GET {baseUrl}/models`
- Response: `{ "object": "list", "data": [{ "id": "model-name", "object": "model", "created": 1686935002, "owned_by": "owner" }, ...] }`
- No server-side filtering — client filters by model ID heuristics:
  - **STT models:** ID contains `whisper` (case-insensitive)
  - **LLM models:** all models not matching STT/embedding/tts/image patterns
- Endpoint is widely supported: OpenAI, Groq, xAI, Google Gemini (via OpenAI compat), OpenRouter, Ollama, vLLM, LM Studio

### FetchModelsResult (sealed class)

`ModelsClient.fetchModels` returns a sealed result type instead of a bare `List<String>`:

```dart
sealed class FetchModelsResult {}
class FetchModelsSuccess extends FetchModelsResult {
  final List<String> models;
}
class FetchModelsFailure extends FetchModelsResult {
  final String reason; // e.g. "401 Unauthorized — check API key"
}
```

Error reason mapping:
- HTTP 401 → "Unauthorized — check API key"
- HTTP 403 → "Access denied — check API key permissions"
- HTTP 404 → "Not found — check endpoint URL"
- HTTP 429 → "Rate limited — try again later"
- HTTP 5xx → "Server error (NNN)"
- Network/timeout → "Network error — check connection"
- Malformed JSON → "Unexpected response format"
- Empty credentials → no fetch attempted (not an error)

### Base URL Path Convention

API clients (`OpenAiClient`, `LlmClient`, `ModelsClient`) append endpoint paths directly to `baseUrl` without inserting `/v1/`. The version path is part of the base URL itself:

| Provider | Base URL | Example full URL |
|---|---|---|
| OpenAI | `https://api.openai.com/v1` | `https://api.openai.com/v1/models` |
| Groq | `https://api.groq.com/openai/v1` | `https://api.groq.com/openai/v1/chat/completions` |
| xAI | `https://api.x.ai/v1` | `https://api.x.ai/v1/models` |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` | `https://generativelanguage.googleapis.com/v1beta/openai/models` |
| OpenRouter | `https://openrouter.ai/api/v1` | `https://openrouter.ai/api/v1/chat/completions` |

**Migration:** On settings load, if a saved `baseUrl` matches a known old-format value (e.g. `https://api.openai.com` without `/v1`), append the version path automatically. Migration is idempotent.

### Model Dropdown (Autocomplete Combo-Box)

**Widget:** `lib/features/settings/ui/model_dropdown.dart` — `ModelDropdown`

Uses `RawAutocomplete<String>` to always render a `TextField` that accepts free typing. Fetched models appear as autocomplete suggestions filtered by the user's input.

**Behavior:**
- Fetches models from `/v1/models` when `baseUrl` and `apiKey` are both non-empty
- Shows loading spinner as a suffix icon while fetching
- On success: models shown as dropdown suggestions, user can still type freely
- On failure: helper text shows specific error reason from `FetchModelsFailure.reason` (e.g. "Unauthorized — check API key"), field still editable
- `ModelType.stt` → filters for whisper models; `ModelType.llm` → filters out non-chat models
- Always enabled when the widget's `enabled` prop is true (not locked by preset selection)

### Settings Auto-Save

Settings are persisted immediately without a Save button:
- **Dropdowns, switches, sliders:** call the corresponding `SettingsCubit.save*()` method in `onChanged`
- **Text fields** (API keys, URLs, model names, prompt, sample rate): use a shared 500ms debounce timer via text controller listeners
- **Volume sliders:** save on `Slider.onChangeEnd` (not on every drag tick)
- **Loop prevention:** `didUpdateWidget` guards controller overwrites with `_setTextIfDifferent()` to avoid save → rebuild → overwrite → save cycles

### Volume Preview Sound

When a volume slider is released (`Slider.onChangeEnd`), the app plays the corresponding sound at the selected volume:
- Recording start volume → `SoundService.playRecordingStart(volume:)` (Tink)
- Recording stop volume → `SoundService.playRecordingStop(volume:)` (Pop)
- Transcription complete volume → `SoundService.playTranscriptionComplete(volume:)` (Glass)

### Theme-Aware Banner Colors

Accessibility permission banners in both `settings_page.dart` and `home_page.dart` use `Theme.of(context).brightness` to select colors:
- **Light mode:** `Colors.green.shade50` bg / `Colors.green.shade700` icon (granted); `Colors.orange.shade50` / `Colors.orange.shade700` (denied)
- **Dark mode:** `Colors.green.shade900.withValues(alpha: 0.3)` bg / `Colors.green.shade300` icon (granted); `Colors.orange.shade900.withValues(alpha: 0.3)` / `Colors.orange.shade300` (denied)

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
| the_logger | ^0.0.20 | Structured logging with console output, masking, sessions, real-time streaming |
| the_logger_viewer_widget | ^0.0.2 | Embeddable in-app log viewer with filtering, search, session navigation |
| logging | latest | Dart standard logging (peer dependency of the_logger) |
| mocktail | 1.0.4 | Test mocking (dev) |
| bloc_test | 10.0.0 | BLoC testing (dev) |

## 7. In-App Log Viewer

### Dependency Change

`the_logger` switches from a local path dependency (`path: ../the/the_logger`) to a pub.dev dependency (`^0.0.20`). Version 0.0.20 adds real-time log streaming via broadcast stream, which `the_logger_viewer_widget` requires for live updates.

`the_logger_viewer_widget` (`^0.0.2`) is added as a pub.dev dependency. It provides a drop-in `TheLoggerViewerWidget` and `TheLoggerViewerPage` that read logs directly from `TheLogger`.

### Navigation

A `_LogsButton` icon button is added to the home page AppBar (alongside History and Settings). It pushes `TheLoggerViewerPage` via `Navigator.push`.

```dart
// In home_page.dart AppBar actions:
const [_LogsButton(), _HistoryButton(), _SettingsButton()]
```

### Widget Integration

No custom cubit or state management needed — `TheLoggerViewerWidget` manages its own state internally. It connects to `TheLogger`'s broadcast stream for real-time updates and reads historical logs from the database.

```dart
class _LogsButton extends StatelessWidget {
  const _LogsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Logs',
      onPressed: () => TheLoggerViewerWidget.show(context),
    );
  }
}
```

### Features (provided by package)

- Responsive layout: table on wide screens (>=600dp), list on narrow
- Color-coded log levels with Material 3 theming
- Multi-level filtering: severity, text search, logger name
- Search term highlighting
- Session navigation with dropdown
- Expandable record details with JSON formatting
- Clipboard copy
- Export with custom callback support
- Real-time streaming updates

## 8. Trailing Space on Text Insertion

When inserting text at the cursor via `pasteAtCursor`, a trailing space is appended so the user can continue typing without manually spacing. This applies only to cursor insertion — clipboard copy is not modified.

**Implementation:** In `ClipboardServiceImpl.pasteAtCursor()`, before calling `insertTextWithFallback`:

```dart
@override
Future<void> pasteAtCursor(String text) async {
  final textToInsert =
      text.isNotEmpty && !text.endsWith(' ') && !text.endsWith('\n')
          ? '$text '
          : text;
  _log.fine('Paste at cursor (${textToInsert.length} chars)');
  await _accessibilityService.insertTextWithFallback(textToInsert);
}
```

**Guard:** No space is added if the text is empty, already ends with a space, or ends with a newline.

## 9. Custom App & Tray Icons

### App Icon

macOS app icons live in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`. The `Contents.json` maps sizes to filenames. Required sizes (all PNG):

| Filename | Size | Usage |
|---|---|---|
| `app_icon_16.png` | 16x16 | Finder list, Spotlight |
| `app_icon_32.png` | 32x32 | Finder list @2x, Dock small |
| `app_icon_64.png` | 64x64 | Dock @2x small |
| `app_icon_128.png` | 128x128 | Finder preview |
| `app_icon_256.png` | 256x256 | Finder preview @2x |
| `app_icon_512.png` | 512x512 | App Store |
| `app_icon_1024.png` | 1024x1024 | App Store @2x |

Generate from a single 1024px source and downscale. `Contents.json` does not need changes — filenames are already correct. **Background must be opaque** (solid or gradient fill) — macOS app icons must not have transparency.

### Tray Icon

Menu bar tray icon at `assets/tray_icon.png`. Must be:
- Monochrome white on **transparent** background (required for macOS template images — system auto-tints for light/dark mode)
- ~18x18px (macOS menu bar standard)
- Simple silhouette readable at small size
- Works as a macOS template image (system auto-tints for light/dark mode)

### Icon Generation

Artwork is generated externally using Nano Banana. Prompts are stored in `specs/icon-prompts.md` for reproducibility.

### Tray Icon Click Handler

The `system_tray` package provides `registerSystemTrayEventHandler` for handling click events. Register a handler in `SystemTrayManager.init()` that calls the `_onShow` callback on left-click (`kSystemTrayEventClick`). Right-click (`kSystemTrayEventRightClick`) already opens the context menu by default.

To prevent duplicate show actions on double-click, use a simple guard: ignore clicks within 300ms of the last handled click.

### Recording Indicator Icon

A second tray icon asset `assets/tray_icon_recording.png` — the same duck silhouette with a red dot overlay in the bottom-right corner. Same constraints as the base icon: monochrome white on transparent background, ~18x18px, except the dot uses a solid red (`#FF3B30`).

Add `setRecording(bool isRecording)` to `SystemTrayManager` which calls `setImage()` to swap between `tray_icon.png` and `tray_icon_recording.png`. Called from the existing BLoC listeners in `home_page.dart` that already update the tooltip.

## 10. Hotkey Rapid Press Race Condition Fix

### Root Cause

`RecordingCubit.startRecording()` is async — it awaits permission checks and `_repository.start()`. In push-to-talk mode, a very fast key-down/key-up fires `startRecording()` then `stopRecording()` before start completes. `stopRecording()` calls `_repository.stop()` on a recorder that hasn't started, returning `null`. Then `startRecording()` finishes and emits `RecordingInProgress` — but there's no way to stop it.

### Fix

Add a `_pendingStop` flag and a `_startInProgress` guard in `RecordingCubit`:

```dart
bool _startInProgress = false;
bool _pendingStop = false;

Future<void> startRecording() async {
  _startInProgress = true;
  _pendingStop = false;
  try {
    // ... existing permission + start logic ...
    _tryEmit(const RecordingInProgress(Duration.zero));
    // ... duration subscription ...
  } on Exception catch (...) {
    // ... error handling ...
  } finally {
    _startInProgress = false;
    if (_pendingStop) {
      _pendingStop = false;
      await stopRecording();
    }
  }
}

Future<void> stopRecording() async {
  if (_startInProgress) {
    _pendingStop = true;
    return;
  }
  // ... existing stop logic ...
}
```

### Behavior

| Scenario | Result |
|---|---|
| Normal press/release | Start completes, then stop runs |
| Rapid press/release (stop during start) | `_pendingStop` set, stop auto-fires after start completes |
| Double-tap toggle mode | Second tap sets `_pendingStop`, recording stops cleanly |

## 11. Theme Selection

### Data Model

Add `themeMode` to `AppSettings`:

```dart
enum AppThemeMode { system, light, dark }
```

Persisted as a string in SharedPreferences key `theme_mode`. Default: `system`.

### Architecture

`SettingsCubit` exposes `themeMode` in `SettingsLoaded` state. `DuckmouthApp` wraps `MaterialApp` in a `BlocBuilder<SettingsCubit, SettingsState>` to reactively apply `ThemeMode`:

```dart
// app.dart
BlocBuilder<SettingsCubit, SettingsState>(
  builder: (context, state) {
    final themeMode = state is SettingsLoaded
        ? state.themeMode
        : ThemeMode.system;
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const HomePage(),
    );
  },
)
```

This requires `SettingsCubit` to be provided above `DuckmouthApp` or at the `MaterialApp` level. Currently it's inside `HomePage` — it needs to move up to `DuckmouthApp`.

### Settings UI

A `DropdownButtonFormField<AppThemeMode>` in the settings page, auto-saved on change (consistent with existing pattern). Placed in a new "Appearance" section at the top of settings.

### Branded Seed Color

`AppTheme` uses `ColorScheme.fromSeed()` with the duck amber color `0xFFE8A838` extracted from the app icon. Material 3 derives the full palette (primary, secondary, tertiary, surface, error, etc.) for both light and dark brightness variants. This replaces the default Material purple (`0xFF6750A4`).

## 12. Distribution

### DMG Packaging

**Tool:** `create-dmg` (Homebrew shell script — `brew install create-dmg`)

**Build script:** `scripts/build_dmg.sh`

```bash
#!/bin/bash
set -euo pipefail

APP_NAME="Duckmouth"
BUILD_DIR="build/macos/Build/Products/Release"
DMG_DIR="build/dmg"
VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}' | cut -d'+' -f1)

# 1. Build release
fvm flutter build macos --release

# 2. Ad-hoc sign (no Developer ID needed)
codesign --force --deep -s - "$BUILD_DIR/$APP_NAME.app"

# 3. Create DMG
mkdir -p "$DMG_DIR"
create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 175 190 \
  --app-drop-link 425 190 \
  "$DMG_DIR/$APP_NAME-$VERSION.dmg" \
  "$BUILD_DIR/$APP_NAME.app"
```

**No code signing or notarization** — the app uses ad-hoc signing only. Users downloading the DMG directly will need to allow it via System Settings → Privacy & Security. Homebrew distribution avoids this by stripping quarantine on install.

### Homebrew Tap

> **Homebrew 5.0.0 (Nov 2025) constraints:** Core `homebrew/cask` now requires codesigning + notarization. The `--no-quarantine` flag is deprecated. Unsigned casks in core will be removed by Sept 2026. A **custom tap** is the only viable path for ad-hoc signed apps.

A separate GitHub repository `homebrew-duckmouth` hosts the cask formula:

```ruby
# Casks/duckmouth.rb
cask "duckmouth" do
  version "1.0.0"
  sha256 "SHA256_OF_DMG"

  url "https://github.com/OWNER/duckmouth/releases/download/v#{version}/Duckmouth-#{version}.dmg"
  name "Duckmouth"
  desc "Speech-to-text macOS app with LLM post-processing"
  homepage "https://github.com/OWNER/duckmouth"

  app "Duckmouth.app"

  # Strip quarantine for unsigned app (replaces deprecated --no-quarantine)
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/Duckmouth.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/com.duckmouth.duckmouth",
    "~/Library/Preferences/com.duckmouth.duckmouth.plist",
    "~/Library/Caches/com.duckmouth.duckmouth",
  ]
end
```

**Install:**
```bash
brew tap OWNER/duckmouth
brew install duckmouth
```

**Known limitations of unsigned distribution:**
- Apple Silicon Macs are stricter about blocking unsigned code than Intel
- Each `brew upgrade` re-quarantines the app — the `postflight` block handles this automatically
- Users installing the DMG directly (without Homebrew) must manually run `xattr -dr com.apple.quarantine /Applications/Duckmouth.app` or allow in System Settings → Privacy & Security
- **Long-term fix:** Apple Developer ID ($99/yr) enables signing + notarization → eligible for core `homebrew/cask` and eliminates all Gatekeeper friction
