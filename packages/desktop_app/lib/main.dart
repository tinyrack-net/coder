import 'package:app/desktop.dart';
import 'package:desktop_app/src/embedded_daemon.dart';
import 'package:flutter/widgets.dart';

/// Injectable desktop runner used to verify the production composition root.
typedef DesktopAppRunner =
    Future<void> Function({
      required List<String> arguments,
      required Future<AppServices> Function() bootstrapServices,
    });

/// Builds desktop services with one shared daemon configuration resolution.
Future<AppServices> createProductionDesktopServices() {
  final adapters = EmbeddedDaemonAdapters();
  return createDesktopServices(
    embeddedLauncher: adapters.launcher,
    embeddedDataEraser: adapters.dataEraser,
  );
}

/// Starts the desktop application through [runner].
Future<void> runProductionDesktopApp({
  required List<String> arguments,
  DesktopAppRunner runner = runDesktopApp,
}) {
  WidgetsFlutterBinding.ensureInitialized();
  return runner(
    arguments: arguments,
    bootstrapServices: createProductionDesktopServices,
  );
}

/// Starts the production desktop application.
Future<void> main(List<String> arguments) =>
    runProductionDesktopApp(arguments: arguments);
