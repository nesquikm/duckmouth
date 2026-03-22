import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var textInsertionChannel: TextInsertionChannel?
  private var soundChannel: SoundChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let messenger = flutterViewController.engine.binaryMessenger

    // Register platform channels.
    textInsertionChannel = TextInsertionChannel(messenger: messenger)
    soundChannel = SoundChannel(messenger: messenger)

    super.awakeFromNib()
  }
}
