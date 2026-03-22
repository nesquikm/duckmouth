# Duckmouth — Speech-to-Text macOS App

## Overview

A macOS desktop app that captures speech via microphone, transcribes it using an OpenAI-compatible API, and optionally post-processes the result with LLM prompts. Supports global hotkeys and lives in both the menu bar and as a regular app window.

## Core Features

### Speech-to-Text
- Record audio from system microphone
- Send audio to an OpenAI-compatible STT API (e.g., Whisper, Groq, self-hosted)
- Configurable API endpoint and model
- Display transcription result in the app

### Post-Processing
- Optionally run transcription through an LLM prompt before output
- Configurable prompts (e.g., fix grammar, summarize, translate, reformat)
- OpenAI-compatible chat API for post-processing

### Text Output
- Copy result to clipboard
- Paste directly into the active app at cursor position (clipboard sandwich: save clipboard, write text, simulate Cmd+V, restore clipboard)

### Sound Feedback
- Play sound on recording start
- Play sound on recording stop
- Play sound when transcription is complete
- Configurable volume for feedback sounds

### Global Hotkeys
- Configurable global keyboard shortcut to start/stop recording
- Push-to-talk mode (hold to record, release to stop)
- Toggle mode (press to start, press again to stop)

### UI
- Menu bar icon with quick access popover (status, start/stop, recent transcriptions)
- Menu bar icon changes appearance when recording is active (e.g., color change)
- Full app window for settings, history, and prompt configuration

### Transcription History
- List of recent transcriptions with timestamps
- Click to copy any past transcription to clipboard
- Clear history option

### Settings
- **API**: Predefined provider presets (OpenAI, Groq, etc.) + custom endpoint URL
- **API Key**: Per-provider API key storage
- **STT Model**: Selectable model per provider
- **Post-processing**: Enable/disable, prompt templates, LLM endpoint/key/model
- **Audio input**: Select microphone / input device
- **Hotkeys**: Configurable global shortcut, choice of push-to-talk vs toggle mode
- **Sounds**: Enable/disable feedback sounds, per-sound volume control
- **Output**: Default action on transcription complete (copy to clipboard, paste at cursor, or both)

## Technical Decisions

### Open
- **Framework**: Flutter (cross-platform potential, packages available for hotkeys/audio/tray) vs Swift (native macOS, lighter, more natural menu bar support)
- **Audio format**: WAV vs compressed before sending to API
- **Local model support**: Whether to support local Whisper inference or API-only

### Settled
- **Platform**: macOS (primary target)
- **STT API**: OpenAI-compatible (configurable endpoint)
- **Post-processing API**: OpenAI-compatible chat completions
