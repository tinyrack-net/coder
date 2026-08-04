import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/desktop_bootstrap.dart';
import 'package:coder_app/src/desktop_shell.dart';
import 'package:coder_app/src/desktop_startup.dart';
import 'package:flutter/material.dart';

/// Starts the desktop widget tree with an injectable bootstrap.
Future<void> runDesktopApp({
  AppServices? services,
  List<String> arguments = const <String>[],
  DesktopWindow? window,
  TrayIcon? tray,
  AutostartRegistration? autostart,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final desktopWindow = window ?? PluginDesktopWindow();
  final resolved = services ?? await createDesktopServices();
  // Visibility is decided before the first frame so a login launch never
  // flashes a window on its way to the tray.
  final startHidden = shouldStartHidden(
    arguments: arguments,
    settings: await resolved.settings.loadSettings(),
  );
  await desktopWindow.prepare(startHidden: startHidden);
  runApp(
    CoderApp(
      services: resolved,
      desktopWindow: desktopWindow,
      trayIcon: tray ?? PluginTrayIcon(),
      autostart: autostart ?? const LaunchAtStartupRegistration(),
      startHidden: startHidden,
    ),
  );
}

/// Starts the production desktop application.
Future<void> main(List<String> arguments) =>
    runDesktopApp(arguments: arguments);
