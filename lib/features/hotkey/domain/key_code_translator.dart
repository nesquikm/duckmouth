/// Translates between USB HID usage codes (used by Flutter's
/// [PhysicalKeyboardKey]) and macOS Carbon key codes (used by the
/// native `hotkey_manager` Swift layer).
///
/// Also provides human-readable labels for display in the UI.
class KeyCodeTranslator {
  const KeyCodeTranslator._();

  /// USB HID usage code → macOS Carbon virtual key code.
  /// Returns `null` for unmapped keys.
  static int? usbHidToCarbon(int usbHid) => _usbHidToCarbonMap[usbHid];

  /// USB HID usage code → human-readable label for display.
  static String usbHidToLabel(int usbHid) =>
      _usbHidToLabelMap[usbHid] ??
      'Key(0x${usbHid.toRadixString(16).padLeft(8, '0')})';

  /// All supported USB HID codes.
  static Iterable<int> get supportedUsbHidCodes => _usbHidToCarbonMap.keys;

  // ── USB HID → Carbon mapping ──
  // Sources:
  //   USB HID Usage Tables (page 53+): https://usb.org/document-library/hid-usage-tables-15
  //   Carbon Events.h: kVK_* constants
  //   Flutter PhysicalKeyboardKey: 0x0007XXYY where XXYY = USB HID usage ID
  static const _usbHidToCarbonMap = <int, int>{
    // Letters (A=0x04 .. Z=0x1D)
    0x00070004: 0,   // A → kVK_ANSI_A
    0x00070005: 11,  // B → kVK_ANSI_B
    0x00070006: 8,   // C → kVK_ANSI_C
    0x00070007: 2,   // D → kVK_ANSI_D
    0x00070008: 14,  // E → kVK_ANSI_E
    0x00070009: 3,   // F → kVK_ANSI_F
    0x0007000a: 5,   // G → kVK_ANSI_G
    0x0007000b: 4,   // H → kVK_ANSI_H
    0x0007000c: 34,  // I → kVK_ANSI_I
    0x0007000d: 38,  // J → kVK_ANSI_J
    0x0007000e: 40,  // K → kVK_ANSI_K
    0x0007000f: 37,  // L → kVK_ANSI_L
    0x00070010: 46,  // M → kVK_ANSI_M
    0x00070011: 45,  // N → kVK_ANSI_N
    0x00070012: 31,  // O → kVK_ANSI_O
    0x00070013: 35,  // P → kVK_ANSI_P
    0x00070014: 12,  // Q → kVK_ANSI_Q
    0x00070015: 15,  // R → kVK_ANSI_R
    0x00070016: 1,   // S → kVK_ANSI_S
    0x00070017: 17,  // T → kVK_ANSI_T
    0x00070018: 32,  // U → kVK_ANSI_U
    0x00070019: 9,   // V → kVK_ANSI_V
    0x0007001a: 13,  // W → kVK_ANSI_W
    0x0007001b: 7,   // X → kVK_ANSI_X
    0x0007001c: 16,  // Y → kVK_ANSI_Y
    0x0007001d: 6,   // Z → kVK_ANSI_Z

    // Numbers (1=0x1E .. 0=0x27)
    0x0007001e: 18,  // 1 → kVK_ANSI_1
    0x0007001f: 19,  // 2 → kVK_ANSI_2
    0x00070020: 20,  // 3 → kVK_ANSI_3
    0x00070021: 21,  // 4 → kVK_ANSI_4
    0x00070022: 23,  // 5 → kVK_ANSI_5
    0x00070023: 22,  // 6 → kVK_ANSI_6
    0x00070024: 26,  // 7 → kVK_ANSI_7
    0x00070025: 28,  // 8 → kVK_ANSI_8
    0x00070026: 25,  // 9 → kVK_ANSI_9
    0x00070027: 29,  // 0 → kVK_ANSI_0

    // Special keys
    0x00070028: 36,  // Return → kVK_Return
    0x00070029: 53,  // Escape → kVK_Escape
    0x0007002a: 51,  // Backspace → kVK_Delete
    0x0007002b: 48,  // Tab → kVK_Tab
    0x0007002c: 49,  // Space → kVK_Space

    // Punctuation
    0x0007002d: 27,  // Minus → kVK_ANSI_Minus
    0x0007002e: 24,  // Equal → kVK_ANSI_Equal
    0x0007002f: 33,  // LeftBracket → kVK_ANSI_LeftBracket
    0x00070030: 30,  // RightBracket → kVK_ANSI_RightBracket
    0x00070031: 42,  // Backslash → kVK_ANSI_Backslash
    0x00070033: 41,  // Semicolon → kVK_ANSI_Semicolon
    0x00070034: 39,  // Quote → kVK_ANSI_Quote
    0x00070035: 50,  // Grave → kVK_ANSI_Grave
    0x00070036: 43,  // Comma → kVK_ANSI_Comma
    0x00070037: 47,  // Period → kVK_ANSI_Period
    0x00070038: 44,  // Slash → kVK_ANSI_Slash

    // Function keys (F1=0x3A .. F12=0x45)
    0x0007003a: 122, // F1 → kVK_F1
    0x0007003b: 120, // F2 → kVK_F2
    0x0007003c: 99,  // F3 → kVK_F3
    0x0007003d: 118, // F4 → kVK_F4
    0x0007003e: 96,  // F5 → kVK_F5
    0x0007003f: 97,  // F6 → kVK_F6
    0x00070040: 98,  // F7 → kVK_F7
    0x00070041: 100, // F8 → kVK_F8
    0x00070042: 101, // F9 → kVK_F9
    0x00070043: 109, // F10 → kVK_F10
    0x00070044: 103, // F11 → kVK_F11
    0x00070045: 111, // F12 → kVK_F12

    // Navigation
    0x00070049: 114, // Insert → kVK_Help (macOS equivalent)
    0x0007004a: 115, // Home → kVK_Home
    0x0007004b: 116, // PageUp → kVK_PageUp
    0x0007004c: 117, // Delete Forward → kVK_ForwardDelete
    0x0007004d: 119, // End → kVK_End
    0x0007004e: 121, // PageDown → kVK_PageDown

    // Arrow keys
    0x0007004f: 124, // Right → kVK_RightArrow
    0x00070050: 123, // Left → kVK_LeftArrow
    0x00070051: 125, // Down → kVK_DownArrow
    0x00070052: 126, // Up → kVK_UpArrow
  };

  // ── USB HID → human-readable label ──
  static const _usbHidToLabelMap = <int, String>{
    // Letters
    0x00070004: 'A',
    0x00070005: 'B',
    0x00070006: 'C',
    0x00070007: 'D',
    0x00070008: 'E',
    0x00070009: 'F',
    0x0007000a: 'G',
    0x0007000b: 'H',
    0x0007000c: 'I',
    0x0007000d: 'J',
    0x0007000e: 'K',
    0x0007000f: 'L',
    0x00070010: 'M',
    0x00070011: 'N',
    0x00070012: 'O',
    0x00070013: 'P',
    0x00070014: 'Q',
    0x00070015: 'R',
    0x00070016: 'S',
    0x00070017: 'T',
    0x00070018: 'U',
    0x00070019: 'V',
    0x0007001a: 'W',
    0x0007001b: 'X',
    0x0007001c: 'Y',
    0x0007001d: 'Z',

    // Numbers
    0x0007001e: '1',
    0x0007001f: '2',
    0x00070020: '3',
    0x00070021: '4',
    0x00070022: '5',
    0x00070023: '6',
    0x00070024: '7',
    0x00070025: '8',
    0x00070026: '9',
    0x00070027: '0',

    // Special keys
    0x00070028: 'Return',
    0x00070029: 'Escape',
    0x0007002a: 'Backspace',
    0x0007002b: 'Tab',
    0x0007002c: 'Space',

    // Punctuation
    0x0007002d: '-',
    0x0007002e: '=',
    0x0007002f: '[',
    0x00070030: ']',
    0x00070031: '\\',
    0x00070033: ';',
    0x00070034: "'",
    0x00070035: '`',
    0x00070036: ',',
    0x00070037: '.',
    0x00070038: '/',

    // Function keys
    0x0007003a: 'F1',
    0x0007003b: 'F2',
    0x0007003c: 'F3',
    0x0007003d: 'F4',
    0x0007003e: 'F5',
    0x0007003f: 'F6',
    0x00070040: 'F7',
    0x00070041: 'F8',
    0x00070042: 'F9',
    0x00070043: 'F10',
    0x00070044: 'F11',
    0x00070045: 'F12',

    // Navigation
    0x00070049: 'Insert',
    0x0007004a: 'Home',
    0x0007004b: 'Page Up',
    0x0007004c: 'Delete',
    0x0007004d: 'End',
    0x0007004e: 'Page Down',

    // Arrow keys
    0x0007004f: 'Right',
    0x00070050: 'Left',
    0x00070051: 'Down',
    0x00070052: 'Up',
  };
}
