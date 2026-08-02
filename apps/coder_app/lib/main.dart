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
Future<void> main() => runPlatformApp(
  isMobile: Platform.isAndroid || Platform.isIOS,
  runDesktop: desktop.main,
  runMobile: mobile.main,
);
