import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/app_services.dart';
import 'package:coder_app/src/remote_bootstrap.dart';
import 'package:flutter/material.dart';

/// Starts the mobile widget tree with an injectable remote-only bootstrap.
Future<void> runMobileApp({AppServices? services}) async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CoderApp(services: services ?? await createRemoteServices()));
}

/// Starts the production mobile application.
Future<void> main() => runMobileApp();
