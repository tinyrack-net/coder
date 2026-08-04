import 'dart:io';

import 'package:coder_app/main_desktop.dart' as desktop;
import 'package:coder_app/main_mobile.dart' as mobile;

/// Dispatches the platform-neutral entry point to the appropriate runner.
Future<void> runPlatformApp({
  required bool isMobile,
  required Future<void> Function() runDesktop,
  required Future<void> Function() runMobile,
}) => isMobile ? runMobile() : runDesktop();

/// Starts Tinyrack Coder for the current operating system.
Future<void> main(List<String> arguments) => runPlatformApp(
  isMobile: Platform.isAndroid || Platform.isIOS,
  // Only the desktop runner is launched by a login item, so only it needs
  // the arguments that launch records.
  runDesktop: () => desktop.main(arguments),
  runMobile: mobile.main,
);
