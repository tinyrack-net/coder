import 'package:app/src/app/coder_app.dart';
import 'package:app/src/app/composition/app_services.dart';
import 'package:app/src/features/boot/presentation/bootstrap_gate.dart';
import 'package:app/src/features/conversation/infrastructure/attachment_io.dart';
import 'package:app/src/features/desktop/application/desktop_startup.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_bootstrap.dart';
import 'package:app/src/features/desktop/infrastructure/desktop_shell.dart';
import 'package:app/src/features/workspace/infrastructure/directory_picker_io.dart';
import 'package:flutter/material.dart';

/// Everything the desktop entrypoint resolves before it can build [CoderApp].
class DesktopBoot {
  /// Bundles one desktop startup result.
  const DesktopBoot({
    required this.services,
    required this.window,
    required this.tray,
    required this.terminator,
    required this.autostart,
    required this.startHidden,
  });

  /// Platform services used by feature controllers.
  final AppServices services;

  /// Native window the app drives.
  final DesktopWindow window;

  /// Tray icon the resident app installs.
  final TrayIcon tray;

  /// Process terminator the quit path ends with.
  final AppTerminator terminator;

  /// Login-item registration port.
  final AutostartRegistration autostart;

  /// Whether the launch should stay in the tray.
  final bool startHidden;
}

/// Starts the desktop widget tree with an injectable bootstrap.
Future<void> runDesktopApp({
  AppServices? services,
  List<String> arguments = const <String>[],
  DesktopWindow? window,
  TrayIcon? tray,
  AppTerminator? terminator,
  AutostartRegistration? autostart,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    BootstrapGate<DesktopBoot>(
      bootstrap: () async {
        final desktopWindow = window ?? PluginDesktopWindow();
        final resolved = services ?? await createDesktopServices();
        // Visibility is decided before the window is prepared so a login
        // launch never flashes a window on its way to the tray.
        final startHidden = shouldStartHidden(
          arguments: arguments,
          settings: await resolved.settings.loadSettings(),
        );
        await desktopWindow.prepare(startHidden: startHidden);
        return DesktopBoot(
          services: resolved,
          window: desktopWindow,
          tray: tray ?? PluginTrayIcon(),
          terminator: terminator ?? const ProcessAppTerminator(),
          autostart: autostart ?? const LaunchAtStartupRegistration(),
          startHidden: startHidden,
        );
      },
      builder: (context, boot) => CoderApp(
        services: boot.services,
        attachmentInput: const NativeAttachmentInput(),
        directoryPicker: const NativeDirectoryPicker(),
        desktopWindow: boot.window,
        trayIcon: boot.tray,
        terminator: boot.terminator,
        autostart: boot.autostart,
        startHidden: boot.startHidden,
      ),
    ),
  );
}

/// Starts the production desktop application.
Future<void> main(List<String> arguments) =>
    runDesktopApp(arguments: arguments);
