/// Determines what happens with the final transcription result.
enum OutputMode {
  /// Copy the result to the system clipboard.
  copy,

  /// Copy to clipboard and simulate Cmd+V to paste at cursor position.
  /// Requires macOS accessibility permissions.
  paste,

  /// Clipboard sandwich: save previous clipboard, paste new text, then
  /// restore the original clipboard contents.
  both;

  /// Human-readable label for the settings UI.
  String get label => switch (this) {
        OutputMode.copy => 'Copy to clipboard',
        OutputMode.paste => 'Paste at cursor',
        OutputMode.both => 'Paste & restore clipboard',
      };
}
