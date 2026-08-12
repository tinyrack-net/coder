import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // The app stays resident in the menu bar with its embedded daemon running,
  // so closing the window must hide it rather than end the process. Quitting
  // is an explicit choice made from the tray menu.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
