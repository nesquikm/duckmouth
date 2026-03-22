# Duckmouth — Speech-to-Text macOS App

A macOS desktop app that captures speech via microphone, transcribes it using an OpenAI-compatible API, and optionally post-processes the result with LLM prompts. Supports global hotkeys and lives in both the menu bar and as a regular app window.

## Tech Stack

- **Language:** Dart 3.11.3
- **Framework:** Flutter 3.41.5 (macOS)
- **Build:** `fvm flutter build macos`
- **Testing:** flutter_test, mocktail, bloc_test
- **State Management:** BLoC/Cubit

## Architecture

```
lib/
├── app/              # App widget, routing, theme
├── features/         # Feature modules (recording, transcription, settings, history)
│   └── <feature>/
│       ├── data/     # Repositories, data sources, DTOs
│       ├── domain/   # Models, interfaces
│       └── ui/       # Widgets, cubits/blocs
├── core/             # Shared utilities, constants, extensions
└── main.dart         # Entry point
test/                 # Mirrors lib/ structure
macos/                # Native macOS runner
specs/                # SDD spec files
```

## Key Commands

```bash
# Development
fvm flutter run -d macos

# Build
fvm flutter build macos

# Test
fvm flutter test

# Analyze (lint + typecheck)
fvm flutter analyze

# Code generation (when using Freezed/json_serializable)
fvm dart run build_runner build --delete-conflicting-outputs
```

**Gate check — must pass before every merge:**

```bash
fvm flutter analyze && fvm flutter test
```

## Key Patterns

- Feature-first directory structure with data/domain/ui layers
- BLoC/Cubit for state management; use `tryEmit()` for safe emission
- OpenAI-compatible API abstraction for both STT and LLM post-processing
- Repository pattern: data sources behind interfaces for testability
- Use `const` constructors for widgets

## Testing Conventions

- **Framework:** flutter_test
- **Mocking:** mocktail (NOT mockito)
- **BLoC testing:** bloc_test
- **File naming:** `*_test.dart`
- **Structure:** `test/` mirrors `lib/`
- **Coverage target:** >=80% for services/domain, >=60% overall

## Specs

Specs live in `specs/` and are the source of truth for what the app should do. All four files must stay consistent with each other and with the code:

- **requirements.md** — functional requirements (FR-*) and acceptance criteria (AC-*), traceability matrix
- **technical-spec.md** — architecture, data models, APIs, design decisions
- **testing-spec.md** — test structure, conventions, coverage targets, test scenarios
- **plan.md** — milestones (M1–M14), tasks, gates, dependency graph

**When adding or changing a feature/milestone:**
1. Update **all four spec files** — not just the plan
2. Add acceptance criteria to requirements.md and traceability matrix entries
3. Add test scenarios to testing-spec.md
4. Update technical-spec.md if architecture, data models, or APIs change
5. Add the milestone to plan.md with tasks, tests, acceptance criteria, and dependency graph

## DO NOT

- Do not commit without user approval
- Do not add features not in the spec
- Do not use bare `flutter` or `dart` commands — always use `fvm flutter` / `fvm dart`
- Do not manually edit `*.g.dart` or `*.freezed.dart` files
- Do not connect to real external APIs in tests — mock all HTTP calls
