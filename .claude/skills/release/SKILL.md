---
name: release
description: Bump version, build DMG, create GitHub Release, and update Homebrew cask formula. Use when shipping a new version.
argument-hint: [major|minor|patch]
disable-model-invocation: true
---

# Release

Build, publish, and distribute a new version of Duckmouth.

**Argument:** `$ARGUMENTS` — bump type: `major`, `minor`, or `patch` (default: `patch`)

## Current state

- pubspec.yaml version: !`grep 'version:' pubspec.yaml | head -1`
- Latest git tag: !`git tag -l 'v*' --sort=-v:refname | head -1 || echo "none"`
- Latest GitHub Release: !`gh release list --limit 1 2>/dev/null || echo "none"`

## Steps

### 1. Determine new version

Read the current version from `pubspec.yaml` (format: `MAJOR.MINOR.PATCH+BUILD`).

Based on `$ARGUMENTS` (default `patch`):
- `patch` → increment PATCH (e.g., 1.0.0 → 1.0.1)
- `minor` → increment MINOR, reset PATCH (e.g., 1.0.3 → 1.1.0)
- `major` → increment MAJOR, reset MINOR and PATCH (e.g., 1.2.3 → 2.0.0)

Always increment the BUILD number by 1.

Show the user the version change and **ask for confirmation** before proceeding.

### 2. Update pubspec.yaml

Update the `version:` line in `pubspec.yaml` with the new version.

### 3. Gate check

Run: `fvm flutter analyze && fvm flutter test`

If this fails, **stop and fix** before continuing. Do NOT proceed with a failing gate.

### 4. Commit version bump

Commit **only** `pubspec.yaml` with message: `Bump version to <new_version>`

### 5. Build DMG

Run: `./scripts/build_dmg.sh`

This builds the release, ad-hoc signs it, and creates the DMG. Capture the SHA256 from the output.

### 6. Create git tag and GitHub Release

```bash
git tag v<VERSION>
git push origin master --tags
```

Create a GitHub Release with:
- Tag: `v<VERSION>`
- Title: `Duckmouth v<VERSION>`
- Asset: the DMG from `build/dmg/Duckmouth-<VERSION>.dmg`
- Body: Generate release notes from commits since the previous tag. Use `git log <prev_tag>..HEAD --oneline` to gather changes. Group into sections (Features, Fixes, Other) if applicable. Include the install instructions block:

```
## Install

### Homebrew (recommended)
\`\`\`bash
brew tap nesquikm/duckmouth
brew install duckmouth
# or upgrade:
brew upgrade duckmouth
\`\`\`

### Manual
Download \`Duckmouth-<VERSION>.dmg\`, open it, drag to Applications. Then run:
\`\`\`bash
xattr -dr com.apple.quarantine /Applications/Duckmouth.app
\`\`\`

**Universal binary** — supports both Apple Silicon (arm64) and Intel (x86_64).
```

### 7. Update Homebrew cask formula

Clone or fetch the tap repo, update `Casks/duckmouth.rb`:
- Update `version` to the new version
- Update `sha256` to the DMG's SHA256

```bash
# Update the tap locally
brew tap nesquikm/duckmouth
TAP_DIR=$(brew --repository nesquikm/duckmouth)

# Edit the formula in the tap directory
# Update version and sha256 in $TAP_DIR/Casks/duckmouth.rb

# Commit and push
cd "$TAP_DIR"
git add Casks/duckmouth.rb
git commit -m "Update duckmouth to <VERSION>"
git push origin main
```

### 8. Verify

Run `brew update && brew upgrade duckmouth` (or install if not installed) to verify the new version installs correctly.

### 9. Report

Show the user:
- Old version → New version
- GitHub Release URL
- SHA256
- Homebrew tap updated: yes/no
- Verification result

## Rules

- **NEVER skip the gate check** — a failing gate means no release
- **ALWAYS ask for confirmation** before proceeding with the version bump
- **ALWAYS push to master** before creating the tag (the tag should point to the committed version bump)
- If any step fails, stop and report — do not continue with a partial release
