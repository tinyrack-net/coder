import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/bootstrap.dart';
import 'package:coder_app/src/desktop_bootstrap.dart';
import 'package:flutter/material.dart';

/// Starts the desktop widget tree with an injectable bootstrap.
Future<void> runDesktopApp({AppBootstrap? bootstrap}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CoderApp(bootstrap: bootstrap ?? DesktopBootstrap()));
}

/// Starts the production desktop application.
Future<void> main() => runDesktopApp();
