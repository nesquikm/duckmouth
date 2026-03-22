import Cocoa
import FlutterMacOS
import ApplicationServices

/// Platform channel for text insertion via macOS Accessibility API.
///
/// Methods:
/// - `checkAccessibilityPermission` → `{ "status": "granted" | "denied" | "unknown" }`
/// - `requestAccessibilityPermission` → triggers System Settings prompt
/// - `insertTextViaAccessibility(text:)` → AX direct insert at focused element
/// - `pasteViaCGEvent(text:)` → clipboard sandwich via CGEvent Cmd+V
class TextInsertionChannel {
    private let channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "com.duckmouth/text_insertion",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkAccessibilityPermission":
            let trusted = AXIsProcessTrusted()
            result(["status": trusted ? "granted" : "denied"])

        case "requestAccessibilityPermission":
            // Trigger the system trust prompt (registers the app in the AX list).
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
            // Also open the Accessibility pane directly so the user sees it.
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
            result(nil)

        case "insertTextViaAccessibility":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing 'text' argument", details: nil))
                return
            }
            let success = insertViaAX(text: text)
            if success {
                result(["success": true])
            } else {
                result(["success": false, "error": "AX insert failed — target app may not support kAXSelectedTextAttribute"])
            }

        case "pasteViaCGEvent":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing 'text' argument", details: nil))
                return
            }
            pasteViaCGEventImpl(text: text, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Attempt to insert text directly via AX API on the focused UI element.
    private func insertViaAX(text: String) -> Bool {
        guard AXIsProcessTrusted() else { return false }

        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusResult == .success, let element = focusedElement else {
            return false
        }

        let axElement = element as! AXUIElement
        let setResult = AXUIElementSetAttributeValue(
            axElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return setResult == .success
    }

    /// Clipboard sandwich via CGEvent: save clipboard → set text → Cmd+V → restore.
    private func pasteViaCGEventImpl(text: String, result: @escaping FlutterResult) {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        // Set clipboard to the new text.
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V via CGEvent.
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
            result(["success": false, "error": "Failed to create CGEvent"])
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        // Restore clipboard after a short delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let previous = previousContents {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
            result(["success": true])
        }
    }
}
