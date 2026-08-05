import Cocoa
import FlutterMacOS
import ServiceManagement

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let project = FlutterDartProject()
    // The stock macOS runner drops the command line, but the login item is
    // told to pass --start-minimized, so it has to reach Dart.
    project.dartEntrypointArguments = MainFlutterWindow.entrypointArguments()

    // The brand tile color the boot splash also paints. Without it the window
    // shows the default light surface until Flutter's first frame arrives.
    self.backgroundColor = NSColor(
      srgbRed: 0x0a / 255.0, green: 0x0a / 255.0, blue: 0x0a / 255.0, alpha: 1.0
    )

    let flutterViewController = FlutterViewController(project: project)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    MainFlutterWindow.registerLoginItemChannel(with: flutterViewController)

    super.awakeFromNib()
  }

  /// Arguments Dart should see, including the flag a login launch implies.
  ///
  /// `SMAppService` starts the app with no extra arguments, so the flag is
  /// synthesized from the launch reason instead of being read from argv.
  private static func entrypointArguments() -> [String] {
    var arguments = Array(CommandLine.arguments.dropFirst())
    if wasLaunchedAtLogin() && !arguments.contains(startMinimizedFlag) {
      arguments.append(startMinimizedFlag)
    }
    return arguments
  }

  private static let startMinimizedFlag = "--start-minimized"

  private static func wasLaunchedAtLogin() -> Bool {
    guard
      let event = NSAppleEventManager.shared().currentAppleEvent,
      event.eventID == kAEOpenApplication,
      let reason = event.paramDescriptor(forKeyword: keyAEPropData)
    else {
      return false
    }
    return reason.enumCodeValue == keyAELaunchedAsLogInItem
  }

  /// Implements the channel `launch_at_startup` calls.
  ///
  /// The plugin ships no macOS code, so the app owns this side. `SMAppService`
  /// keeps it dependency-free at the cost of requiring macOS 13.
  private static func registerLoginItemChannel(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "launch_at_startup",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "launchAtStartupIsEnabled":
        result(SMAppService.mainApp.status == .enabled)
      case "launchAtStartupSetEnabled":
        let arguments = call.arguments as? [String: Any]
        let enabled = arguments?["setEnabledValue"] as? Bool ?? false
        do {
          if enabled {
            try SMAppService.mainApp.register()
          } else {
            try SMAppService.mainApp.unregister()
          }
          result(nil)
        } catch {
          result(
            FlutterError(
              code: "launch_at_startup_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
