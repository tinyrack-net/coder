import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/desktop_bootstrap.dart';
import 'package:flutter/material.dart';

/// Starts the desktop widget tree with an injectable bootstrap.
Future<void> runDesktopApp({AppServices? services}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CoderApp(services: services ?? await createDesktopServices()));
}

/// Starts the production desktop application.
Future<void> main() => runDesktopApp();
