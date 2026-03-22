import Cocoa
import FlutterMacOS

/// Platform channel for playing macOS system sounds via NSSound.
///
/// Methods:
/// - `playSound(name: String, volume: Double)` → plays the named system sound
class SoundChannel {
    private let channel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "com.duckmouth/sound",
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler(handle)
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "playSound":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing 'name' argument", details: nil))
                return
            }

            let volume = (args["volume"] as? Double) ?? 1.0
            let clampedVolume = min(max(volume, 0.0), 1.0)

            guard let sound = NSSound(named: name) else {
                // Sound not found — non-critical, return success: false
                result(["success": false, "error": "Sound '\(name)' not found"])
                return
            }

            sound.volume = Float(clampedVolume)
            sound.play()
            result(["success": true])

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
